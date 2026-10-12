# CURRENT_TASK.md

### T-111 · [S] Define ImageSourceApi in pigeons/messages.dart

- Files: pigeons/messages.dart
- Do: Add a new @HostApi() at top level of the file. DO NOT touch any existing class.
  Add exactly this code:

  @HostApi()
  abstract class ImageSourceApi {
  /// Returns JPEG bytes of the picked image, or null if the user cancelled.
  @async
  Uint8List? pickImageFromGallery();

      /// Returns JPEG bytes of the captured photo, or null if the user cancelled.
      @async
      Uint8List? takePhotoWithCamera();
  }

  If Uint8List is not imported, add "import 'dart:typed_data';" at the top.
  If @async is not recognized, ensure "import 'package:pigeon/pigeon.dart';" is at the top.

- Don't:
  - Do NOT rename or remove any existing class, method or field.
  - Do NOT modify the existing CaptureApi / OcrApi / TranslationApi / SelectionApi.
  - Do NOT add any other file.

- Ctx: AGENTS.md, AGENTS.PROJECT.md, pigeons/messages.dart

- Done when:
  - dart analyze pigeons/messages.dart has no new errors
  - The file still contains all previously existing classes

- Status: TODO
