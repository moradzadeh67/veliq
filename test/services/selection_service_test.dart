import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/pigeon/messages.g.dart';
import 'package:veliq/services/pigeon_selection_service.dart';

class MockSelectionApi extends SelectionApi {
  CaptureRect? mockResult;
  int calls = 0;

  @override
  Future<CaptureRect?> selectRegion() async {
    calls++;
    return mockResult;
  }
}

void main() {
  group('PigeonSelectionService', () {
    test('returns the region reported by the native overlay', () async {
      final mockApi = MockSelectionApi()
        ..mockResult = CaptureRect(x: 10, y: 20, width: 100, height: 200);

      final service = PigeonSelectionService(api: mockApi);
      final region = await service.selectRegion();

      expect(region, isNotNull);
      expect(region!.x, equals(10));
      expect(region.y, equals(20));
      expect(region.width, equals(100));
      expect(region.height, equals(200));
    });

    test('propagates a null result when the user cancels', () async {
      final mockApi = MockSelectionApi()..mockResult = null;

      final service = PigeonSelectionService(api: mockApi);

      expect(await service.selectRegion(), isNull);
    });

    test('treats a degenerate region as a cancellation', () async {
      // Guards against a stray click producing a 0x0 capture.
      final mockApi = MockSelectionApi()
        ..mockResult = CaptureRect(x: 5, y: 5, width: 0, height: 0);

      final service = PigeonSelectionService(api: mockApi);

      expect(await service.selectRegion(), isNull);
    });

    test('delegates exactly once per call', () async {
      final mockApi = MockSelectionApi()
        ..mockResult = CaptureRect(x: 0, y: 0, width: 40, height: 40);

      final service = PigeonSelectionService(api: mockApi);
      await service.selectRegion();
      await service.selectRegion();

      expect(mockApi.calls, equals(2));
    });
  });
}
