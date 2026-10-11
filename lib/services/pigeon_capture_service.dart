import 'dart:typed_data';

import '../pigeon/messages.g.dart';
import 'capture_service.dart';

/// Implementation of [CaptureService] using Pigeon to communicate with macOS native code.
class PigeonCaptureService implements CaptureService {
  final ScreenCaptureApi _api;

  PigeonCaptureService({ScreenCaptureApi? api})
    : _api = api ?? ScreenCaptureApi();

  @override
  Future<Uint8List?> captureRegion({
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    final rect = CaptureRect(x: x, y: y, width: width, height: height);
    return await _api.captureRegion(rect);
  }
}
