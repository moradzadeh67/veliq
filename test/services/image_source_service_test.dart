// ignore_for_file: unnecessary_import, non_constant_identifier_names

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/pigeon/messages.g.dart';
import 'package:veliq/services/pigeon_image_source_service.dart';

class _FakeImageSourceApi implements ImageSourceApi {
  _FakeImageSourceApi({this.galleryBytes, this.cameraBytes});

  final Uint8List? galleryBytes;
  final Uint8List? cameraBytes;

  @override
  BinaryMessenger? get pigeonVar_binaryMessenger => null;

  @override
  String get pigeonVar_messageChannelSuffix => '';

  @override
  Future<Uint8List?> pickImageFromGallery() async => galleryBytes;

  @override
  Future<Uint8List?> takePhotoWithCamera() async => cameraBytes;
}

void main() {
  group('PigeonImageSourceService', () {
    test('pickFromGallery returns bytes from the API', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final service = PigeonImageSourceService(
        _FakeImageSourceApi(galleryBytes: bytes),
      );
      expect(await service.pickFromGallery(), bytes);
    });

    test('pickFromGallery returns null on cancel', () async {
      final service = PigeonImageSourceService(_FakeImageSourceApi());
      expect(await service.pickFromGallery(), isNull);
    });

    test('takePhoto returns bytes from the API', () async {
      final bytes = Uint8List.fromList([4, 5, 6]);
      final service = PigeonImageSourceService(
        _FakeImageSourceApi(cameraBytes: bytes),
      );
      expect(await service.takePhoto(), bytes);
    });

    test('takePhoto returns null on cancel', () async {
      final service = PigeonImageSourceService(_FakeImageSourceApi());
      expect(await service.takePhoto(), isNull);
    });
  });
}
