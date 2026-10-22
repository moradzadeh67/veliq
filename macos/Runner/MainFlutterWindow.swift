import Cocoa
import FlutterMacOS
import Foundation
import ScreenCaptureKit
import Translation
import Vision

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let messenger = flutterViewController.engine.binaryMessenger
    SelectionApiSetup.setUp(binaryMessenger: messenger, api: SelectionHandler())
    ScreenCaptureApiSetup.setUp(binaryMessenger: messenger, api: ScreenCaptureHandler())
    OcrApiSetup.setUp(binaryMessenger: messenger, api: OcrHandler())
    TranslationApiSetup.setUp(binaryMessenger: messenger, api: TranslationHandler())

    super.awakeFromNib()
  }
}

/// Presents the native full-screen region picker and reports the chosen region.
class SelectionHandler: SelectionApi {
  func selectRegion() async throws -> CaptureRect? {
    return await withCheckedContinuation { continuation in
      Task { @MainActor in
        SelectionOverlayController.shared.begin { rect in
          continuation.resume(returning: rect)
        }
      }
    }
  }
}

class ScreenCaptureHandler: ScreenCaptureApi {
  func captureRegion(rect: CaptureRect) async throws -> FlutterStandardTypedData? {
    // `rect` arrives in global, top-left-origin screen points (the space the
    // overlay produces and SCDisplay.frame uses).
    let globalRect = CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
    guard globalRect.width >= 1, globalRect.height >= 1 else {
      return nil
    }

    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

    // Pick the display the selection actually falls on, rather than assuming
    // the first one. Multi-display setups have non-zero origins for every
    // display but the primary one.
    let center = CGPoint(x: globalRect.midX, y: globalRect.midY)
    guard let display = content.displays.first(where: { $0.frame.contains(center) })
        ?? content.displays.first
    else {
      return nil
    }

    // Never let Veliq's own windows (including the selection overlay) bleed
    // into the screenshot.
    let ownApplication = content.applications.first {
      $0.bundleIdentifier == Bundle.main.bundleIdentifier
    }
    let filter = SCContentFilter(
      display: display,
      excludingApplications: ownApplication.map { [$0] } ?? [],
      exceptingWindows: []
    )

    // `sourceRect` is display-local, in points, top-left origin, and
    // `SCDisplay.frame` lives in the same Quartz global space the overlay
    // reports (verified on hardware: the secondary display's SCDisplay.frame
    // was (1728, 0, ...) while its NSScreen.frame was (1728, -323, ...)), so
    // only the display origin has to be subtracted — no flip.
    let localRect = CGRect(
      x: globalRect.minX - display.frame.minX,
      y: globalRect.minY - display.frame.minY,
      width: globalRect.width,
      height: globalRect.height
    )
    let sourceRect = localRect.intersection(filter.contentRect)
    guard !sourceRect.isNull, sourceRect.width >= 1, sourceRect.height >= 1 else {
      return nil
    }

    let scale = Self.pointPixelScale(for: filter, displayID: display.displayID)

    let config = SCStreamConfiguration()
    config.sourceRect = sourceRect
    // `width`/`height` are in pixels while `sourceRect` is in points, so the
    // backing scale factor has to be applied or Retina captures come back at a
    // quarter of the intended resolution.
    config.width = max(1, Int((sourceRect.width * scale).rounded()))
    config.height = max(1, Int((sourceRect.height * scale).rounded()))

    let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    return Self.pngData(from: cgImage)
  }

  /// Points-to-pixels factor for the display being captured.
  private static func pointPixelScale(for filter: SCContentFilter, displayID: CGDirectDisplayID) -> CGFloat {
    if #available(macOS 14.0, *) {
      return CGFloat(filter.pointPixelScale)
    }

    let screenNumberKey = NSDeviceDescriptionKey("NSScreenNumber")
    let screen = NSScreen.screens.first {
      ($0.deviceDescription[screenNumberKey] as? CGDirectDisplayID) == displayID
    }
    return screen?.backingScaleFactor ?? 1
  }

  private static func pngData(from cgImage: CGImage) -> FlutterStandardTypedData? {
    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    guard let tiffData = nsImage.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
      return nil
    }
    return FlutterStandardTypedData(bytes: pngData)
  }
}

class OcrHandler: OcrApi {
  func recognizeText(imageBytes: FlutterStandardTypedData, languageHint: String?) async throws -> String? {
    let data = imageBytes.data
    guard let cgImage = NSImage(data: data)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }

    return try await withCheckedThrowingContinuation { continuation in
      let request = VNRecognizeTextRequest { request, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }

        let observations = request.results as? [VNRecognizedTextObservation] ?? []
        let recognizedStrings = observations.compactMap { observation in
          observation.topCandidates(1).first?.string
        }
        let fullText = recognizedStrings.joined(separator: "\n")
        continuation.resume(returning: fullText.isEmpty ? nil : fullText)
      }

      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true

      do {
        try OcrHandler.applyLanguageHint(languageHint, to: request)
      } catch {
        continuation.resume(throwing: error)
        return
      }

      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      do {
        try handler.perform([request])
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  /// ISO 639-1 base codes the current Vision revision can read (D-018).
  ///
  /// Derived from Vision at runtime rather than hard-coded: the list changes
  /// between macOS releases.
  func supportedLanguages() async throws -> [String] {
    return OcrHandler.baseCodes(OcrHandler.visionLanguages)
  }

  /// Base codes ("zh-Hans" -> "zh", "fr-FR" -> "fr"), de-duplicated, ordered.
  private static func baseCodes(_ identifiers: [String]) -> [String] {
    var seen = Set<String>()
    var codes: [String] = []
    for identifier in identifiers {
      let code = baseCode(identifier)
      if !code.isEmpty && seen.insert(code).inserted {
        codes.append(code)
      }
    }
    return codes
  }

  private static func baseCode(_ identifier: String) -> String {
    return identifier.split(separator: "-").first.map(String.init)?.lowercased()
      ?? identifier.lowercased()
  }

  /// Every language the accurate recognizer supports, or an empty list on
  /// systems predating the query API.
  private static var visionLanguages: [String] {
    guard #available(macOS 11.0, *) else { return [] }
    let probe = VNRecognizeTextRequest()
    probe.recognitionLevel = .accurate
    return (try? probe.supportedRecognitionLanguages()) ?? []
  }

  /// Applies [hint] to [request]: `nil`/`auto` lets Vision detect the script,
  /// otherwise the request is restricted to the matching Vision languages.
  private static func applyLanguageHint(_ hint: String?, to request: VNRecognizeTextRequest) throws {
    guard #available(macOS 11.0, *) else { return }

    guard let hint = hint, !hint.isEmpty, hint != "auto" else {
      request.automaticallyDetectsLanguage = true
      return
    }

    let matches = ((try? request.supportedRecognitionLanguages()) ?? [])
      .filter { baseCode($0) == hint.lowercased() }

    guard !matches.isEmpty else {
      throw NSError(
        domain: "com.moradzadeh67.veliq.ocr",
        code: 1,
        userInfo: [
          NSLocalizedDescriptionKey:
            "Text recognition is not available for language '\(hint)' on this Mac."
        ])
    }

    request.recognitionLanguages = matches
    request.automaticallyDetectsLanguage = false
  }
}

class TranslationHandler: TranslationApi {
  func translateText(text: String, sourceLanguage: String, targetLanguage: String) async throws -> String? {
    // The programmatic (non-SwiftUI) TranslationSession API is only available on
    // macOS 26.0+. On older systems the Dart side falls back gracefully (null).
    guard #available(macOS 26.0, *) else {
      return nil
    }

    let source = Locale.Language(identifier: sourceLanguage)
    let target = Locale.Language(identifier: targetLanguage)
    let session = TranslationSession(installedSource: source, target: target)
    try await session.prepareTranslation()
    let response = try await session.translate(text)
    return response.targetText
  }
}