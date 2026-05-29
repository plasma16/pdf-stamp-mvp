## 2026-05-23 10:40 SGT
- Added `pubspec.yaml`, `analysis_options.yaml`, `.gitignore` for new `pdf-stamp-mvp` Flutter MVP module.
- Added `lib/main.dart` implementing offline PDF stamping flow: pick PDF, pick PNG stamp, auto white-to-transparent cleanup, drag/resize/rotate placement, page selection, and export `*_stamped.pdf`.
- Added `README.md` with setup, package stack, and MVP limitations.
- Validation: Could not run Flutter commands in this environment because `flutter` is not installed (`flutter: command not found`).

## 2026-05-23 11:45 SGT
- Added `.github/workflows/build-apk.yml` to build a release Android APK on GitHub Actions for push, pull request, and manual runs.
- Updated `README.md` with CI artifact details and steps to download `app-release.apk` from workflow artifacts.
- Validation: Workflow syntax reviewed locally; could not execute GitHub Actions in this environment.

## 2026-05-23 11:52 SGT
- Updated `.github/workflows/build-apk.yml` to bootstrap the missing Android host project in CI using `flutter create --platforms=android` when `android/` is absent.
- This fixes the GitHub Actions error: unsupported Gradle project during `flutter build apk --release`.
- Validation: Change reviewed locally; workflow execution pending on next GitHub push.

## 2026-05-23 12:00 SGT
- Updated `lib/main.dart` to alias Syncfusion PDF imports (`sfpdf`) and explicitly reference `sfpdf.PdfDocument`/`sfpdf.PdfBitmap`.
- This resolves the GitHub Actions compile error where `PdfDocument` was imported from both `pdfx` and `syncfusion_flutter_pdf`.
- Validation: Static review only in this environment; Flutter build execution pending in GitHub Actions.

## 2026-05-23 12:06 SGT
- Updated `.github/workflows/build-apk.yml` to set Android `compileSdk` and `targetSdk` to `36` after CI bootstrap.
- This addresses the Actions failure from `:file_picker:checkReleaseAarMetadata` requiring Android API 36.
- Validation: Log-driven fix; pending verification in next GitHub Actions run.

## 2026-05-23 12:14 SGT
- Updated `.github/workflows/build-apk.yml` to enforce `flutter.compileSdkVersion=36` and `flutter.targetSdkVersion=36` in `android/gradle.properties` during CI.
- This makes plugin modules (including `file_picker`) compile against API 36, not just the app module.
- Validation: Log-driven fix; pending verification in next GitHub Actions run.

## 2026-05-23 12:41 SGT
- Updated `.github/workflows/build-apk.yml` to add a CI patch step that rewrites `compileSdk`/`targetSdk` to `36` across Gradle files in workspace and `$HOME/.pub-cache` after `flutter pub get`.
- This addresses plugin-level Android API mismatches where `file_picker` still compiled against android-34 in GitHub Actions.
- Validation: Log-driven fix; pending verification in next GitHub Actions run.

## 2026-05-23 12:55 SGT
- Updated `lib/main.dart` to add a new `Combine 2 PDFs` action using Syncfusion PDF append flow.
- Added two-file picker validation (requires exactly 2 PDFs), merge/export logic, and UI loading state during combine.
- Output is saved beside the first selected PDF as `<file1>_<file2>_combined.pdf`.
- Validation: Static review only in this environment; Flutter runtime/build not executed locally because Flutter SDK is unavailable.

## 2026-05-23 13:46 SGT
- Updated `lib/main.dart` PDF combine implementation to remove unsupported `appendDocument` calls in `syncfusion_flutter_pdf` 26.2.14.
- Replaced merge logic with explicit page copy using `createTemplate()` + `drawPdfTemplate(...)` into destination pages sized to source pages.
- This fixes GitHub Actions compile failure: `The method 'appendDocument' isn't defined for the type 'PdfDocument'`.
- Validation: Log-driven code fix; local Flutter build not run because Flutter SDK is unavailable in this environment.

## 2026-05-23 14:07 SGT
- Updated `.github/workflows/build-apk.yml` to harden CI Android SDK patching for plugin Gradle scripts.
- Added rewrite rules for `safeExtGet(..., 34/35)` patterns and a verification print for `file_picker` Gradle SDK lines from `$HOME/.pub-cache` before build.
- This targets repeated `:file_picker:checkReleaseAarMetadata` failures where the plugin still resolved to android-34.
- Validation: Log-driven workflow fix; pending verification in next GitHub Actions run.

## 2026-05-23 14:16 SGT
- Updated `.github/workflows/build-apk.yml` to set root Android Gradle `ext.compileSdkVersion=36` and `ext.targetSdkVersion=36` (and Kotlin DSL equivalent `extra[...]`) after CI bootstrap.
- This directly fixes plugin `safeExtGet('compileSdkVersion', 34)` fallback behavior used by `file_picker`, so plugin modules resolve API 36 instead of 34.
- Validation: Log-driven workflow fix; pending verification in next GitHub Actions run.

## 2026-05-23 14:28 SGT
- Updated `.github/workflows/build-apk.yml` to remove CI dependency on `rg` (replaced with portable `grep -E` checks), since runner image lacked `rg`.
- Added additional Gradle rewrite rules for `compileSdk 34` / `targetSdk 34` syntax (space-separated form) used by `file_picker` plugin scripts.
- This directly targets the latest failure where post-patch verification still showed `file_picker` as `compileSdk 34`.
- Validation: Log-driven workflow fix; pending verification in next GitHub Actions run.

## 2026-05-23 15:43 SGT
- Updated `lib/main.dart` stamp import flow to accept JPG/JPEG in addition to PNG (`allowedExtensions: ['png', 'jpg', 'jpeg']`).
- Renamed picker action to `Pick Stamp Image` and generalized error text from PNG-specific wording.
- Existing white-background cleanup pipeline remains in place and now runs for both PNG and JPG/JPEG inputs before stamping.
- Validation: Static code review only; local Flutter build/test not run because Flutter SDK is unavailable in this environment.

## 2026-05-24 01:36 SGT
- Incremented version in pubspec.yaml from 0.1.0+1 to 0.1.0+2 to allow reinstallation of APK with same version name.
- Commit pubspec.yaml.

## 2026-05-24 02:23 SGT
- Enhanced PDF stamp interaction:
  * Added scrollbar for easier PDF navigation
  * Added tap-to-place stamp functionality on PDF pages
  * Added stamp tap-to-enter move mode (drag to reposition)
  * Added visual feedback (opacity change) when stamp is in move mode
  * Improved stamp positioning controls
- Updated lib/main.dart with gesture handling and state management


## 2026-05-24 02:55 SGT
- Added delete function for PDF stamp:
  * Tap on stamp shows dialog with Move and Delete options
  * Delete option removes the stamp image and resets state
  * Move option enters drag-to-reposition mode
  * Enhanced user interaction with clear feedback
- Updated lib/main.dart with _handlePdfTap and _handleStampTap methods

## 2026-05-29 19:08 SGT
- Fixed APK build failure from GitHub Actions run 26350203189 by repairing Dart syntax/type issues in `lib/main.dart` introduced in commit `841ddd7`.
- Removed invalid `_tapPosition` assignment (field not defined), removed unsupported `onTapDown` parameter from `PdfViewPinch`, and corrected malformed widget tree around `Scrollbar`/`GestureDetector`/`Transform.rotate` so the file parses and compiles.
- Changed files: `lib/main.dart`.
- Validation: root cause confirmed from Actions logs (`lib/main.dart` compile errors at lines 314/439/442/446); local Flutter build not executed because Flutter SDK is unavailable in this environment (`flutter: command not found`).

## 2026-05-29 19:28 SGT
- Updated `.github/workflows/build-apk.yml` so CI sets APK build number from `${{ github.run_number }}` during `flutter build apk --release`.
- This prevents Android install conflicts from repeated artifacts sharing the same versionCode.
- Changed files: `.github/workflows/build-apk.yml`.
- Validation: Diff reviewed locally; workflow execution will be validated on next GitHub Actions run after push.

## 2026-05-29 19:32 SGT
- Updated `lib/main.dart` layout handling to improve viewport safety and prevent constrained preview sizing issues.
- Added `SafeArea` wrapping and computed `previewHeight` from safe body height (`MediaQuery` minus padding and toolbar), clamped between `200` and `700`.
- Applied computed `previewHeight` to the PDF preview `SizedBox` to keep the editor usable across screen sizes.
- Changed files: `lib/main.dart`, `data/daily_change_log.md`.
- Validation: `git diff --stat` confirms only intended tracked files changed; local Flutter runtime/build not executed in this environment because Flutter SDK is unavailable.

## 2026-05-29 19:44 SGT
- Updated `lib/main.dart` preview sizing to explicitly account for Android bottom navigation/system bar inset using the larger of `MediaQuery.padding.bottom` and `MediaQuery.viewPadding.bottom`.
- This ensures preview height calculation reserves bottom system UI space consistently across gesture/navigation modes.
- Changed files: `lib/main.dart`, `data/daily_change_log.md`.
- Validation: local Flutter run/analyze not executed because Flutter SDK is unavailable in this environment (`flutter: command not found`).

## 2026-05-29 19:47 SGT
- Redesigned app UI with modern glassmorphism aesthetic.
- Added deep purple/indigo gradient background (`_kBgGradient`), frosted-glass cards (`_GlassCard` with `BackdropFilter`), glowing gradient primary button, icon-labelled buttons, labelled slider rows with live values, info chips for file status, pill page indicator, and transparent blurred AppBar.
- Dialog updated with icon list tiles. Stamp move mode shows inline "Done Moving" badge.
- All existing functionality (export, combine, page range, sliders, stamp drag/delete, safe insets) preserved.
- Changed files: `lib/main.dart`, `data/daily_change_log.md`.
- Validation: static review only; Flutter SDK unavailable in this environment.

## 2026-05-29 20:01 SGT
- Implemented behavior updates in `lib/main.dart`:
  - Output files now always save next to the input PDF using `_buildUniqueSiblingFile(...)` (same directory, collision-safe suffix numbering).
  - In moving-stamp mode, single-finger touch/drag anywhere on the PDF preview repositions the stamp.
  - Two-finger gestures no longer move the stamp (pointer tracking), allowing PDF gesture handling underneath.
- Changed files: `lib/main.dart`, `data/daily_change_log.md`.
- Validation: static diff review only; local `flutter`/`dart` commands unavailable in this environment.

## 2026-05-29 20:36 SGT
- Updated `lib/main.dart` stamp interaction state by replacing prior page-range/delete controller fields with paste/move interaction helpers (`_isPasteMode`, `_movingPointerOffset`, `_isInteractingWithStamp`, `_stampBounds`, `_isPointOnStamp`).
- Simplified state lifecycle by removing unused text controller disposal paths tied to removed page-range inputs.
- Changed files: `lib/main.dart`, `data/daily_change_log.md`.
- Validation: verified local git diff and staging scope; Flutter SDK is unavailable in this environment, so runtime/build validation was not executed.

## 2026-05-29 20:55 SGT
- Moved all controls into Drawer; removed SingleChildScrollView; PDF fills full screen.
- Stamp image no longer rendered on pick — held in `_pendingStampPng` until user taps PDF to place.
- On paste tap: `_pendingStampPng` → `_cleanedStampPng`, stamp becomes visible at tap location.
- Changed files: `lib/main.dart`, `data/daily_change_log.md`.
- Validation: static review only; Flutter SDK unavailable.

## 2026-05-29 21:29 SGT
- Tightened move-stamp interaction in `lib/main.dart`: drag now starts only when touch begins on the stamp; background drag no longer repositions the stamp (prevents accidental PDF-scroll vs move conflicts).
- Added move hint snackbar when drag starts outside the stamp in move mode.
- Fixed output path handling when Android file picker returns app-cache paths: exports now prefer `/storage/emulated/0/Download` fallback instead of app cache, with snackbar note explaining fallback.
- Updated save confirmation messages to display resolved output path via `_displaySavedPath(...)`.
- Changed files: `lib/main.dart`, `data/daily_change_log.md`.
- Validation: static code review and targeted diff checks only; Flutter SDK unavailable in this environment.

## 2026-05-29 21:39 SGT
- Fixed stamp-drag regression: moved move-mode pan handlers from the full PDF overlay `GestureDetector` to the stamp widget `GestureDetector` itself.
- Result: dragging works when touching the stamp, while PDF keeps native scroll/zoom gestures when touching background.
- Kept paste-mode tap handler on the PDF-level overlay for intentional placement flow.
- Changed files: `lib/main.dart`, `data/daily_change_log.md`.
- Validation: static code review and targeted diff checks only; Flutter SDK unavailable in this environment.

## 2026-05-29 21:40 SGT
- Changed export behavior in `lib/main.dart` to stamp only the currently viewed page (`_pageNumber`) instead of all pages.
- This aligns with tap-to-place expectation: one placement affects one selected page.
- Changed files: `lib/main.dart`, `data/daily_change_log.md`.
- Validation: static code review and targeted diff checks only; Flutter SDK unavailable in this environment.

## 2026-05-29 21:45 SGT
- Added manual background transparency control in burger menu (`lib/main.dart`) with persistent opacity slider (`_stampOpacity`) and saved preference key `stamp_opacity` via `shared_preferences`.
- Added live preview panel in drawer showing current opacity effect (`Preview XX%`) using the processed stamp image.
- Applied opacity setting consistently to on-canvas stamp rendering and exported PDF output (`setTransparency(_stampOpacity)`).
- Added dependency `shared_preferences: ^2.3.2` in `pubspec.yaml`.
- Changed files: `lib/main.dart`, `pubspec.yaml`, `data/daily_change_log.md`.
- Validation: static diff/code review only; Flutter SDK unavailable in this environment.

## 2026-05-29 21:51 SGT
- Ran Flutter validation in `/home/linuxuser/pdf-stamp-mvp`: `flutter pub get` completed successfully and `flutter analyze` completed with 9 pre-existing issues (warnings/info) in `lib/main.dart`, no new code changes required for this task.
- Appended this log entry with current SGT timestamp.
- Changed files: `data/daily_change_log.md`.
- Validation: command output captured locally in this environment.

