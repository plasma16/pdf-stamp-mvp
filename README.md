# PDF Stamp MVP (Offline, Phone)

Flutter MVP for stamping a local PDF with a local PNG stamp, fully offline.

## Features
- Pick source PDF from local storage.
- Pick PNG stamp from local storage.
- Automatically convert white/near-white stamp background to transparent.
- Drag stamp on page preview, resize and rotate.
- Apply stamp to all pages or a page range.
- Export a new file beside the original: `*_stamped.pdf`.

## Notes
- MVP supports PNG stamp input directly.
- If your stamp is PDF, convert it to PNG first (first page only), then use this app.
- PDF size guard: 50MB.

## Stack
- `file_picker`
- `image`
- `pdfx`
- `syncfusion_flutter_pdf`

## Run
1. Install Flutter SDK.
2. From project root:
   - `flutter pub get`
   - `flutter run`

## Known MVP limitations
- Placement mapping from preview to PDF page is approximate and works best for standard page aspect ratios.
- No multi-stamp layers yet.
- No undo stack yet.

## CI APK Build (GitHub Actions)
- Workflow file: `.github/workflows/build-apk.yml`
- Triggers: every push, pull request, and manual `workflow_dispatch`.
- Output artifact: `app-release-apk` containing `app-release.apk`.

### Download APK from GitHub
1. Open your repository on GitHub.
2. Click the latest workflow run under `Actions`.
3. Download the `app-release-apk` artifact.

