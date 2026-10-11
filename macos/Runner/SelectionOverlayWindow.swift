import Cocoa

/// A borderless, transparent window that can cover a whole display and become
/// key, so it can receive Escape without permanently stealing focus.
private final class OverlayPanel: NSWindow {
  override var canBecomeKey: Bool { return true }
  override var canBecomeMain: Bool { return true }
}

/// Draws the dimming layer plus the rubber-band cut-out for one display.
private final class OverlayView: NSView {
  /// The display this view covers, in AppKit (bottom-left origin) coordinates.
  let screenFrame: NSRect

  init(frame: NSRect, screenFrame: NSRect) {
    self.screenFrame = screenFrame
    super.init(frame: frame)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override var isOpaque: Bool { return false }

  // MARK: - Coordinate helpers

  /// AppKit window-local point -> global top-left (Quartz style) point.
  ///
  /// The overlay spans the display, so the window origin equals the display
  /// origin and this is a straight translation plus a y flip.
  private func globalTopLeft(fromLocal point: NSPoint) -> NSPoint {
    let flip = SelectionOverlayController.flipReferenceY
    return NSPoint(
      x: screenFrame.origin.x + point.x,
      y: flip - (screenFrame.origin.y + point.y)
    )
  }

  /// Inverse of `globalTopLeft(fromLocal:)`.
  private func local(fromGlobalTopLeft point: NSPoint) -> NSPoint {
    let flip = SelectionOverlayController.flipReferenceY
    return NSPoint(
      x: point.x - screenFrame.origin.x,
      y: flip - point.y - screenFrame.origin.y
    )
  }

  // MARK: - Drawing

  override func draw(_ dirtyRect: NSRect) {
    let dim = NSColor.black.withAlphaComponent(0.35)

    guard let global = SelectionOverlayController.shared.selectionRect,
      global.width >= 1, global.height >= 1
    else {
      // Nothing selected yet: dim the whole display.
      dim.setFill()
      bounds.fill()
      return
    }

    // Map the global selection into this window, then rebuild it as an AppKit
    // rect (bottom-left origin) so it can be punched out of the dim layer.
    let topLeft = local(fromGlobalTopLeft: NSPoint(x: global.minX, y: global.minY))
    let bottomRight = local(
      fromGlobalTopLeft: NSPoint(x: global.maxX, y: global.maxY))
    let cutout = NSRect(
      x: topLeft.x,
      y: bottomRight.y,
      width: max(0, bottomRight.x - topLeft.x),
      height: max(0, topLeft.y - bottomRight.y)
    )

    // Even-odd winding: the outer bounds are dimmed, the cut-out stays clear.
    // Drawn as a single fill so the dim is not applied twice.
    let mask = NSBezierPath(rect: bounds)
    mask.appendRect(cutout)
    mask.windingRule = .evenOdd
    dim.setFill()
    mask.fill()

    NSColor.controlAccentColor.setStroke()
    let border = NSBezierPath(rect: cutout)
    border.lineWidth = 2
    border.stroke()
  }

  // MARK: - Mouse

  override func mouseDown(with event: NSEvent) {
    let point = convert(event.locationInWindow, from: nil)
    SelectionOverlayController.shared.beginDrag(at: globalTopLeft(fromLocal: point))
  }

  override func mouseDragged(with event: NSEvent) {
    let point = convert(event.locationInWindow, from: nil)
    SelectionOverlayController.shared.updateDrag(to: globalTopLeft(fromLocal: point))
  }

  override func mouseUp(with event: NSEvent) {
    let point = convert(event.locationInWindow, from: nil)
    SelectionOverlayController.shared.updateDrag(to: globalTopLeft(fromLocal: point))
    SelectionOverlayController.shared.finishDrag()
  }
}

/// Presents a borderless overlay across **every** attached display so the user
/// can drag a region over any application, including outside Veliq's window.
///
/// Only one session can be active at a time; a concurrent call resolves
/// immediately with `nil`.
final class SelectionOverlayController {
  static let shared = SelectionOverlayController()

  private var windows: [OverlayPanel] = []
  private var keyMonitor: Any?
  private var previousKeyWindow: NSWindow?
  private var completion: ((CaptureRect?) -> Void)?
  private var cursorPushed = false

  private(set) var startPoint: NSPoint?
  private(set) var currentPoint: NSPoint?

  private init() {}

  /// The y used to flip AppKit's bottom-left space into the app's top-left
  /// space. Both `NSScreen` and `SCDisplay` frames are anchored to the primary
  /// display, so the primary display's height is the correct reference.
  static var flipReferenceY: CGFloat {
    return NSScreen.screens.first?.frame.maxY ?? 0
  }

  var isActive: Bool { return completion != nil }

  /// The in-progress selection in global top-left points, or nil.
  var selectionRect: NSRect? {
    guard let start = startPoint, let current = currentPoint else { return nil }
    return NSRect(
      x: min(start.x, current.x),
      y: min(start.y, current.y),
      width: abs(current.x - start.x),
      height: abs(current.y - start.y)
    )
  }

  // MARK: - Session lifecycle

  func begin(completion: @escaping (CaptureRect?) -> Void) {
    guard !isActive, !NSScreen.screens.isEmpty else {
      completion(nil)
      return
    }

    self.completion = completion
    self.startPoint = nil
    self.currentPoint = nil
    self.previousKeyWindow = NSApp.keyWindow

    for screen in NSScreen.screens {
      let panel = OverlayPanel(
        contentRect: screen.frame,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false,
        screen: screen
      )
      panel.isOpaque = false
      panel.backgroundColor = .clear
      panel.hasShadow = false
      panel.isReleasedWhenClosed = false
      panel.level = .screenSaver
      panel.collectionBehavior = [
        .canJoinAllSpaces,
        .fullScreenAuxiliary,
        .stationary,
        .ignoresCycle,
      ]
      panel.acceptsMouseMovedEvents = true
      panel.contentView = OverlayView(
        frame: NSRect(origin: .zero, size: screen.frame.size),
        screenFrame: screen.frame
      )
      panel.setFrame(screen.frame, display: false)
      panel.orderFrontRegardless()
      windows.append(panel)
    }

    // Own the keyboard so Escape reaches us.
    windows.first?.makeKey()

    keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
      [weak self] event in
      guard let self = self else { return event }
      if event.keyCode == 53 {  // Escape
        self.finish(cancelled: true)
        return nil
      }
      return event
    }

    if !cursorPushed {
      cursorPushed = true
      NSCursor.crosshair.push()
    }
  }

  func beginDrag(at point: NSPoint) {
    startPoint = point
    currentPoint = point
    refreshOverlays()
  }

  func updateDrag(to point: NSPoint) {
    currentPoint = point
    refreshOverlays()
  }

  /// Called on mouse-up. A click or a degenerate drag keeps the overlay up so
  /// the user can try again; a real drag ends the session.
  func finishDrag() {
    guard isActive else { return }

    guard let rect = selectionRect, rect.width >= 2, rect.height >= 2 else {
      startPoint = nil
      currentPoint = nil
      refreshOverlays()
      return
    }

    finish(cancelled: false)
  }

  func refreshOverlays() {
    for panel in windows {
      panel.contentView?.needsDisplay = true
    }
  }

  /// Tears the overlay down and hands the result to the waiting caller.
  private func finish(cancelled: Bool) {
    guard let completion = completion else { return }
    self.completion = nil

    let rect = selectionRect

    if let monitor = keyMonitor {
      NSEvent.removeMonitor(monitor)
      keyMonitor = nil
    }

    // Tear the overlay down *before* the caller screenshots, otherwise the
    // dimming would be baked into the captured image.
    for panel in windows {
      panel.orderOut(nil)
    }
    windows.removeAll()

    startPoint = nil
    currentPoint = nil

    if cursorPushed {
      cursorPushed = false
      NSCursor.pop()
    }

    // Give focus back to the app window the user came from.
    if let previous = previousKeyWindow, previous.isVisible {
      previous.makeKey()
    }
    previousKeyWindow = nil

    guard !cancelled, let rect = rect else {
      completion(nil)
      return
    }

    completion(
      CaptureRect(
        x: Double(rect.minX),
        y: Double(rect.minY),
        width: Double(rect.width),
        height: Double(rect.height)
      )
    )
  }
}