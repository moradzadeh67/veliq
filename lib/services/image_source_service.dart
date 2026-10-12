import 'dart:typed_data';

/// Abstracts image acquisition so tests and other platforms can provide fakes.
abstract class ImageSourceService {
  /// Returns JPEG bytes of the picked image, or null if the user cancelled.
  Future<Uint8List?> pickFromGallery();

  /// Returns JPEG bytes of the captured photo, or null if the user cancelled.
  Future<Uint8List?> takePhoto();
}
