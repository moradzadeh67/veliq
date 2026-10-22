import Flutter
import UIKit
import Vision

/// iOS OCR backend: Apple Vision, fully on-device (T-153, D-018).
///
/// The image never leaves the process: bytes -> `UIImage` -> `CGImage` ->
/// `VNImageRequestHandler`. Nothing is logged, written to disk or uploaded.
class OcrHandler: OcrApi {
  func recognizeText(imageBytes: FlutterStandardTypedData, languageHint: String?) async throws -> String? {
    guard let image = UIImage(data: imageBytes.data),
          let cgImage = image.cgImage else {
      return nil
    }

    // Camera and gallery JPEGs often carry an EXIF rotation; Vision must be told
    // about it or the recognized text is wrong.
    let orientation = OcrHandler.orientation(of: image)

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

      let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
      do {
        try handler.perform([request])
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  /// ISO 639-1 base codes the current Vision revision can read (D-018).
  ///
  /// Derived from Vision at runtime rather than hard-coded: the list depends on
  /// the iOS version.
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

  /// Every language the accurate recognizer supports.
  private static var visionLanguages: [String] {
    let probe = VNRecognizeTextRequest()
    probe.recognitionLevel = .accurate
    return (try? probe.supportedRecognitionLanguages()) ?? []
  }

  /// Applies [hint] to [request]: `nil`/`auto` lets Vision detect the script,
  /// otherwise the request is restricted to the matching Vision languages.
  private static func applyLanguageHint(_ hint: String?, to request: VNRecognizeTextRequest) throws {
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
            "Text recognition is not available for language '\(hint)' on this device."
        ])
    }

    request.recognitionLanguages = matches
    request.automaticallyDetectsLanguage = false
  }

  /// Maps `UIImage.Orientation` onto the `CGImagePropertyOrientation` Vision
  /// expects, so an EXIF-rotated photo is read the right way up.
  private static func orientation(of image: UIImage) -> CGImagePropertyOrientation {
    switch image.imageOrientation {
    case .up:
      return .up
    case .upMirrored:
      return .upMirrored
    case .down:
      return .down
    case .downMirrored:
      return .downMirrored
    case .left:
      return .left
    case .leftMirrored:
      return .leftMirrored
    case .right:
      return .right
    case .rightMirrored:
      return .rightMirrored
    @unknown default:
      return .up
    }
  }
}
