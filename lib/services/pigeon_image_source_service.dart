import 'dart:typed_data';

import '../pigeon/messages.g.dart';
import 'image_source_service.dart';

class PigeonImageSourceService implements ImageSourceService {
  PigeonImageSourceService([ImageSourceApi? api])
    : _api = api ?? ImageSourceApi();

  final ImageSourceApi _api;

  @override
  Future<Uint8List?> pickFromGallery() => _api.pickImageFromGallery();

  @override
  Future<Uint8List?> takePhoto() => _api.takePhotoWithCamera();
}
