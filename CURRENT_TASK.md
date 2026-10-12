# CURRENT_TASK.md

### T-100 · [L] Research: iOS image acquisition strategy   ⚠ strong model

- Files: docs/ARCHITECTURE.md (add rows D-010, D-011, D-012 only)
- Do: Decide and document (with Apple official sources):
  1. Gallery: PHPickerViewController (PhotosUI) vs UIImagePickerController.
  2. Camera: UIImagePickerController (rear camera, .photo).
  3. Entitlements: which Info.plist keys are required for (1) and (2)?
  4. iOS minimum version (recommend iOS 16+).
  5. Defer decision: Share Extension (out of scope for MVP).
  6. Defer decision: ReplayKit (why it does not solve our use case).
- Don't: no production code, no Swift, no Dart, no pubspec changes.
- Ctx: AGENTS.md, AGENTS.PROJECT.md
- Done when: D-010, D-011, D-012 rows written in docs/ARCHITECTURE.md with status DECIDED or UNVERIFIED, each with a source URL.
- Status: TODO
