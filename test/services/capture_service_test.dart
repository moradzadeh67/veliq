import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/pigeon/messages.g.dart';
import 'package:veliq/services/pigeon_capture_service.dart';

class MockScreenCaptureApi extends ScreenCaptureApi {
  CaptureRect? lastRect;
  Uint8List? mockResult;

  @override
  Future<Uint8List?> captureRegion(CaptureRect rect) async {
    lastRect = rect;
    return mockResult;
  }
}

void main() {
  group('PigeonCaptureService', () {
    test(
      'captureRegion passes coordinates correctly to ScreenCaptureApi',
      () async {
        final mockApi = MockScreenCaptureApi();
        final expectedBytes = Uint8List.fromList([1, 2, 3, 4]);
        mockApi.mockResult = expectedBytes;

        final service = PigeonCaptureService(api: mockApi);
        final result = await service.captureRegion(
          x: 10.0,
          y: 20.0,
          width: 100.0,
          height: 200.0,
        );

        expect(result, equals(expectedBytes));
        expect(mockApi.lastRect, isNotNull);
        expect(mockApi.lastRect!.x, equals(10.0));
        expect(mockApi.lastRect!.y, equals(20.0));
        expect(mockApi.lastRect!.width, equals(100.0));
        expect(mockApi.lastRect!.height, equals(200.0));
      },
    );
  });
}
