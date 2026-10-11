import 'dart:typed_data';

/// Abstract service interface for capturing screen regions.
abstract class CaptureService {
  /// Captures a screen region defined by [x], [y], [width], and [height].
  /// Returns PNG or JPEG image bytes, or null if capture fails/cancelled.
  Future<Uint8List?> captureRegion({
    required double x,
    required double y,
    required double width,
    required double height,
  });
}
