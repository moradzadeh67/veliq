import '../models/screen_region.dart';
import '../pigeon/messages.g.dart';
import 'selection_service.dart';

/// Implementation of [SelectionService] that delegates to the native
/// full-screen overlay window through Pigeon.
class PigeonSelectionService implements SelectionService {
  final SelectionApi _api;

  PigeonSelectionService({SelectionApi? api}) : _api = api ?? SelectionApi();

  @override
  Future<ScreenRegion?> selectRegion() async {
    final rect = await _api.selectRegion();
    if (rect == null) return null;

    final region = ScreenRegion(
      x: rect.x,
      y: rect.y,
      width: rect.width,
      height: rect.height,
    );
    return region.isUsable ? region : null;
  }
}
