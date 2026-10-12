# CURRENT_TASK.md

### T-110 · [S] Add iOS Info.plist privacy usage descriptions

- Files: ios/Runner/Info.plist
- Do: Add ONLY these keys inside the top-level <dict>:
  <key>NSCameraUsageDescription</key>
  <string>Veliq reads text from a photo you take, to translate it. Photos never leave your device.</string>
  Do NOT add NSPhotoLibraryUsageDescription — D-012 says it is not required (PHPickerViewController is out-of-process).
- Don't: no other key, no other file, do not reorder existing keys.
- Ctx: AGENTS.md, AGENTS.PROJECT.md, ios/Runner/Info.plist, docs/ARCHITECTURE.md (row D-012 only)
- Done when: `plutil -lint ios/Runner/Info.plist` prints "OK"
- Status: TODO
