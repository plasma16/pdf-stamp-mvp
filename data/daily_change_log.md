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
