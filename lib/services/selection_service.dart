import '../models/screen_region.dart';

/// Presents a screen region picker to the user.
///
/// Implementations must be able to draw *outside* the application window, so a
/// pure Flutter widget is not a valid implementation — see
/// `macos/Runner/SelectionOverlayWindow.swift`.
abstract class SelectionService {
  /// Shows the picker and completes with the region the user dragged out, or
  /// with `null` if they cancelled (Escape, or a degenerate drag).
  Future<ScreenRegion?> selectRegion();
}
