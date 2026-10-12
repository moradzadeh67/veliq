# CURRENT_TASK.md

## Batch: T-114, T-115, T-116, T-117 (all [S])

Do all four tasks in order. After each task, STOP and report a short STATUS line
so I can verify before you continue. Do not skip steps.

---

### T-114 · [S] Add ImageSourceService Dart interface

- Files:
  lib/services/image_source_service.dart (new)
  lib/services/pigeon_image_source_service.dart (new)

- Do:

  Step 1 — Create lib/services/image_source_service.dart with EXACTLY:

  import 'dart:typed_data';

  /// Abstracts image acquisition so tests and other platforms can provide fakes.
  abstract class ImageSourceService {
  /// Returns JPEG bytes of the picked image, or null if the user cancelled.
  Future<Uint8List?> pickFromGallery();

      /// Returns JPEG bytes of the captured photo, or null if the user cancelled.
      Future<Uint8List?> takePhoto();
  }

  Step 2 — Create lib/services/pigeon_image_source_service.dart with EXACTLY:

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

- Don't:
  - Do NOT modify any other file.
  - Do NOT add packages.
  - Do NOT touch existing services.
  - If the generated class name in lib/pigeon/messages.g.dart is NOT "ImageSourceApi",
    STOP and report the actual name.

- Ctx: AGENTS.md, AGENTS.PROJECT.md, lib/pigeon/messages.g.dart (to confirm class name)

- Done when: flutter analyze lib/services 2>&1 | tail -5 is clean.

- REPORT after this task: STATUS line only, then continue.

---

### T-115 · [S] Unit test for PigeonImageSourceService with fake

- Files:
  test/services/image_source_service_test.dart (new)

- Do:
  Create the file with EXACTLY this content:

  import 'dart:typed_data';

  import 'package:flutter_test/flutter_test.dart';
  import 'package:veliq/pigeon/messages.g.dart';
  import 'package:veliq/services/image_source_service.dart';
  import 'package:veliq/services/pigeon_image_source_service.dart';

  class _FakeImageSourceApi implements ImageSourceApi {
  _FakeImageSourceApi({this.galleryBytes, this.cameraBytes});

      final Uint8List? galleryBytes;
      final Uint8List? cameraBytes;

      @override
      Future<Uint8List?> pickImageFromGallery() async => galleryBytes;

      @override
      Future<Uint8List?> takePhotoWithCamera() async => cameraBytes;
  }

  void main() {
  group('PigeonImageSourceService', () {
  test('pickFromGallery returns bytes from the API', () async {
  final bytes = Uint8List.fromList([1, 2, 3]);
  final service = PigeonImageSourceService(_FakeImageSourceApi(galleryBytes: bytes));
  expect(await service.pickFromGallery(), bytes);
  });

        test('pickFromGallery returns null on cancel', () async {
          final service = PigeonImageSourceService(_FakeImageSourceApi());
          expect(await service.pickFromGallery(), isNull);
        });

        test('takePhoto returns bytes from the API', () async {
          final bytes = Uint8List.fromList([4, 5, 6]);
          final service = PigeonImageSourceService(_FakeImageSourceApi(cameraBytes: bytes));
          expect(await service.takePhoto(), bytes);
        });

        test('takePhoto returns null on cancel', () async {
          final service = PigeonImageSourceService(_FakeImageSourceApi());
          expect(await service.takePhoto(), isNull);
        });
      });
  }

  If the import path package:veliq/... does not match the real package name,
  read pubspec.yaml first and use the correct name.

- Don't:
  - Do NOT modify lib/.
  - Do NOT add packages.

- Ctx: AGENTS.md, AGENTS.PROJECT.md, pubspec.yaml (package name),
  lib/pigeon/messages.g.dart (confirm ImageSourceApi exists)

- Done when:
  flutter test test/services/image_source_service_test.dart 2>&1 | tail -5 shows all tests pass.

- REPORT after this task: STATUS line only, then continue.

---

### T-116 · [S] Wire ImageSourceService into TranslateFlowBloc

- Files:
  lib/features/translation/bloc/translate_flow_bloc.dart
  lib/features/translation/bloc/translate_flow_state.dart (only if needed)
  test/features/translation/bloc/translate_flow_bloc_test.dart

- Do:
  1. Read lib/features/translation/bloc/translate_flow_bloc.dart first.
  2. Add ImageSourceService as a constructor dependency of TranslateFlowBloc.
     Keep the parameter optional (nullable) or with a default so existing tests
     and existing call sites do NOT break.
  3. Add two new events: PickImageFromGallery and TakePhoto (follow the existing
     event naming style in the same file).
  4. Add handlers for these events that:
     a. call imageSourceService.pickFromGallery() or takePhoto()
     b. if the returned bytes are null → emit a state indicating cancel
     (reuse the closest existing state; do NOT invent new complex states)
     c. if bytes are non-null → run the EXACT SAME pipeline as the existing
     capture-based flow (OCR → translate → save to history)
  5. Add at least two unit tests in translate_flow_bloc_test.dart using a fake
     ImageSourceService: one success, one cancel.

- Don't:
  - Do NOT modify ocr_bloc.dart or translation_bloc.dart.
  - Do NOT redesign existing states.
  - Do NOT break existing tests.

- Ctx: AGENTS.md, AGENTS.PROJECT.md,
  lib/features/translation/bloc/translate_flow_bloc.dart (read before editing),
  lib/services/image_source_service.dart

- Done when:
  flutter test test/features/translation/bloc/translate_flow_bloc_test.dart 2>&1 | tail -5
  shows all tests pass (old + new), and flutter analyze lib/features/translation is clean.

- REPORT after this task: STATUS line only, then continue.

---

### T-117 · [S] Add iOS capture buttons in TranslateView

- Files:
  lib/features/translation/translate_view.dart
  test/features/translation/translate_view_test.dart (extend if it exists)

- Do:
  1. Read lib/features/translation/translate_view.dart first.
  2. Find the existing "Select region" button/action that triggers the capture
     pipeline on macOS.
  3. Wrap that action in a platform check:
     if (defaultTargetPlatform == TargetPlatform.iOS) → show two buttons:
     "Pick image" (Icons.photo_library) → dispatches PickImageFromGallery
     "Take photo" (Icons.photo_camera) → dispatches TakePhoto
     else → keep the existing "Select region" button unchanged.
  4. If translate_view_test.dart exists, add one widget test verifying that on
     TargetPlatform.iOS the two buttons are found.
     Use debugDefaultTargetPlatformOverride to simulate iOS in the test.

- Don't:
  - Do NOT redesign the layout.
  - Do NOT touch the result panel, history, or settings views.
  - Do NOT break existing macOS behavior.

- Ctx: AGENTS.md, AGENTS.PROJECT.md,
  lib/features/translation/translate_view.dart (read before editing)

- Done when:
  flutter analyze lib/features/translation is clean and
  flutter test test/features/translation 2>&1 | tail -5 passes.

- REPORT after this task: final STATUS for the whole batch.

---

## Batch rules
- Do the four tasks in strict order.
- After each task, output one line:
  T-11X DONE — <file list> — <verify command result>
  Then continue to the next task automatically.
- If any task fails, STOP, report BLOCKED with the exact error, and do NOT
  continue to the next task.
- Do NOT run git.
- Do NOT touch TASKS.md. Only CURRENT_TASK.md is yours to read.