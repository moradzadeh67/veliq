import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeon/messages.g.dart',
    swiftOut: 'macos/Runner/Messages.g.swift',
  ),
)
/// A rectangle in **global screen points** with a top-left origin, expressed
/// relative to the primary display.
///
/// This matches what [SelectionApi.selectRegion] returns, so the value can be
/// forwarded to [ScreenCaptureApi.captureRegion] unchanged. The native side is
/// responsible for resolving which display the rect belongs to and for
/// converting points to backing pixels.
class CaptureRect {
  final double x;
  final double y;
  final double width;
  final double height;

  CaptureRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

@HostApi()
abstract class PingApi {
  String ping(String message);
}

@HostApi()
abstract class SelectionApi {
  /// Presents a native, borderless, full-screen region picker that covers every
  /// attached display, so the user can drag a selection over any application.
  ///
  /// Returns the chosen region, or null when the user cancels with Escape (or
  /// with an empty drag).
  @async
  CaptureRect? selectRegion();
}

@HostApi()
abstract class ScreenCaptureApi {
  /// Captures [rect] (see [CaptureRect] for the coordinate space) and returns
  /// PNG bytes, or null when the region or display cannot be resolved.
  @async
  Uint8List? captureRegion(CaptureRect rect);
}

@HostApi()
abstract class OcrApi {
  @async
  String? recognizeText(Uint8List imageBytes);
}

@HostApi()
abstract class TranslationApi {
  @async
  String? translateText(
    String text,
    String sourceLanguage,
    String targetLanguage,
  );
}
