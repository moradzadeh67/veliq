# CURRENT_TASK.md
Active: none. P12 — Android v1 (gallery + camera -> local ML Kit OCR -> Gemini with the user's key -> History/Settings) is closed. Decision D-016, scope in PROJECT_SPEC.md ("Android scope"), tasks T-131..T-139 in TASKS.md.

Status: P12 COMPLETE — T-131..T-139 all DONE (2026-10-15). Commands green (analyze 0, tests 199/199, apk built) and the full 8-item emulator checklist verified, including items 7-8 after the owner entered the Gemini key ("Connected. The API key works."): a real en->fa translation succeeded and the History entry survived am force-stop + relaunch. No task is active; waiting for the owner's next instruction (commit/push is pending owner approval). Docs refreshed on 2026-10-15 to match the shipped Android v1: README.md (status, features, tech stack, testing, permissions, privacy, install, roadmap, limitations), PROJECT_SPEC.md ("Android scope"), docs/ARCHITECTURE.md (D-016 + Android data flow/components/permissions), docs/PRIVACY.md (Android flows, image sources, key storage, history path) and docs/RELEASE.md.

Notes for a future session:
- The Android icon generator was a one-off script in /tmp (not committed). If icons need regenerating, either re-run it or add Android outputs to assets/app_icon/source/generate_icons.sh (owner approval needed).
- "Select another region" is still the iOS wording on the result screen (iOS is not in the P12 scope); fix with the iOS wording pass if ever wanted.
- Latin-only ML Kit OCR: Persian/Arabic script needs a separate model — open idea, not scheduled.
- Test images that had been pushed to the emulator (/sdcard/Pictures/veliq-*.png, four files incl. older T-134/T-136 ones) were deleted at the owner's request (2026-10-15).
- Work through T-138 is uncommitted. Suggested commit: `git add -A && git commit -m "Android v1 (P12): scaffold, UI, Pigeon Kotlin bridge, gallery/camera input, ML Kit OCR, Gemini-only settings, launcher icon and metadata"`.

Earlier work through T-129 (in-app keyboard shortcuts) is committed and pushed (origin/main 6f2de5c). Separate open item: the T-124 remainder checklist on the iOS simulator (cancel path, revoked-permission message, history across restart; camera stays device-only, out of scope).
