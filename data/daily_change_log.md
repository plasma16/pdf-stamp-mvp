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
