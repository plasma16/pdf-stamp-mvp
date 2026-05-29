import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';


import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;

// ── Glassmorphism design tokens ──────────────────────────────────────────────
const _kBgGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
);

const _kGlassColor    = Color(0x22FFFFFF);
const _kGlassBorder   = Color(0x44FFFFFF);
const _kAccentPrimary = Color(0xFF7B61FF);
const _kAccentSecond  = Color(0xFF00D2FF);
const _kTextPrimary   = Color(0xFFF0F0FF);
const _kTextSecond    = Color(0xAAC8C8E8);
const _kAggressivenessPrefKey = 'stamp_bg_aggressiveness';
const _kDefaultAggressiveness = 55.0;
const _kCachedStampPathKey = 'cached_stamp_path';
const _kCachedStampIsPdfKey = 'cached_stamp_is_pdf';

// ── App entry ─────────────────────────────────────────────────────────────────
void main() {
  runApp(const PdfStampMvpApp());
}

class PdfStampMvpApp extends StatelessWidget {
  const PdfStampMvpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Stamp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF7B61FF),
        scaffoldBackgroundColor: const Color(0xFF0F0C29),
        sliderTheme: const SliderThemeData(
          activeTrackColor: _kAccentPrimary,
          thumbColor: _kAccentPrimary,
          inactiveTrackColor: Color(0x44FFFFFF),
          overlayColor: Color(0x337B61FF),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: _kTextSecond),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kGlassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kAccentPrimary, width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0x15FFFFFF),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF302B63),
          contentTextStyle: const TextStyle(color: _kTextPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1E1B3A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF1A1640),
        ),
      ),
      home: const StampHomePage(),
    );
  }
}

// ── Reusable glass card ───────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding, this.margin});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGlassBorder, width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x33FFFFFF), Color(0x0AFFFFFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Slider row ────────────────────────────────────────────────────────────────
class _LabelledSlider extends StatelessWidget {
  const _LabelledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              color: _kTextSecond,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            value.toStringAsFixed(0),
            style: const TextStyle(color: _kTextSecond, fontSize: 11),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter({this.cellSize = 8});
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFECECEC);
    final dark = Paint()..color = const Color(0xFFD8D8D8);

    for (double y = 0; y < size.height; y += cellSize) {
      for (double x = 0; x < size.width; x += cellSize) {
        final isDark = ((x / cellSize).floor() + (y / cellSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isDark ? dark : light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) {
    return oldDelegate.cellSize != cellSize;
  }
}

class _PlacedStamp {
  _PlacedStamp({
    required this.png,
    required this.x,
    required this.y,
    required this.baseWidth,
    required this.baseHeight,
    required this.scale,
    required this.rotationDeg,
  });

  Uint8List png;
  double x;
  double y;
  double baseWidth;
  double baseHeight;
  double scale;
  double rotationDeg;

  double get w => baseWidth * scale;
  double get h => baseHeight * scale;

  Rect get bounds => Rect.fromLTWH(x, y, w, h);
}

class _ImageDimensions {
  const _ImageDimensions(this.width, this.height);

  final double width;
  final double height;
}

// ── Main page ─────────────────────────────────────────────────────────────────
class StampHomePage extends StatefulWidget {
  const StampHomePage({super.key});

  @override
  State<StampHomePage> createState() => _StampHomePageState();
}

class _StampHomePageState extends State<StampHomePage> {
  File? _pdfFile;
  File? _stampFile;
  Uint8List? _rawStampBytes;
  Uint8List? _stampSourcePdfBytes; // Original PDF bytes when stamp is a PDF
  Uint8List? _pendingStampPng; // held until user taps to place
  final List<_PlacedStamp> _placedStamps = [];
  int? _selectedStampIndex;

  PdfControllerPinch? _pdfController;
  final GlobalKey _previewStackKey = GlobalKey();

  int _pageNumber = 1;
  int _pageCount = 1;

  double _pendingStampBaseW = 140;
  double _pendingStampBaseH = 90;
  double _pendingStampScale = 1.0;
  double _rotationDeg = 0;
  double _aggressiveness = _kDefaultAggressiveness;

  static const double _minStampScale = 0.25;
  static const double _maxStampScale = 3.2;

  double get _pendingStampW => _pendingStampBaseW * _pendingStampScale;
  double get _pendingStampH => _pendingStampBaseH * _pendingStampScale;

  bool _isMovingStamp = false;
  bool _isPasteMode = false;

  bool _isExporting = false;
  bool _isCombining = false;

  Offset? _movingPointerOffset;

  _PlacedStamp? get _selectedStamp =>
      (_selectedStampIndex != null &&
              _selectedStampIndex! >= 0 &&
              _selectedStampIndex! < _placedStamps.length)
          ? _placedStamps[_selectedStampIndex!]
          : null;

  bool _isPointOnSelectedStamp(Offset pos) {
    final selected = _selectedStamp;
    if (selected == null) return false;
    return selected.bounds.contains(pos);
  }

  Uint8List? get _activePreviewStampPng =>
      _pendingStampPng ??
      _selectedStamp?.png ??
      (_placedStamps.isNotEmpty ? _placedStamps.last.png : null);

  @override
  void initState() {
    super.initState();
    _loadStampSettings();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadStampSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAggressiveness = prefs.getDouble(_kAggressivenessPrefKey);
    if (!mounted) return;

    setState(() {
      if (savedAggressiveness != null) {
        _aggressiveness = savedAggressiveness.clamp(0.0, 100.0).toDouble();
      }
    });

    await _loadCachedStamp();
  }

  Future<void> _saveAggressiveness(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kAggressivenessPrefKey, value);
  }

  Future<void> _cacheStampBytes(Uint8List bytes, {required bool isPdf}) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final ext = isPdf ? '.pdf' : '.png';
      final cacheFile = File(p.join(dir.path, 'cached_stamp$ext'));
      await cacheFile.writeAsBytes(bytes, flush: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCachedStampPathKey, cacheFile.path);
      await prefs.setBool(_kCachedStampIsPdfKey, isPdf);
    } catch (_) {
      // Silent fail — caching is best-effort
    }
  }

  Future<void> _loadCachedStamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPath = prefs.getString(_kCachedStampPathKey);
      if (cachedPath == null) return;

      final cachedFile = File(cachedPath);
      if (!await cachedFile.exists()) {
        // Cache file gone — clear prefs
        await prefs.remove(_kCachedStampPathKey);
        await prefs.remove(_kCachedStampIsPdfKey);
        return;
      }

      final isPdf = prefs.getBool(_kCachedStampIsPdfKey) ?? false;
      final fileBytes = await cachedFile.readAsBytes();

      // For PDF stamps, rasterize for preview (same as _readStampSourceBytes)
      Uint8List rasterBytes;
      if (isPdf) {
        final pdf = await PdfDocument.openData(fileBytes);
        try {
          if (pdf.pagesCount < 1) return;
          final page = await pdf.getPage(1);
          try {
            final longestSide = page.width > page.height ? page.width : page.height;
            final scale = (1024.0 / longestSide).clamp(0.25, 1.0);
            final rendered = await page.render(
              width: (page.width * scale).roundToDouble(),
              height: (page.height * scale).roundToDouble(),
              format: PdfPageImageFormat.png,
              backgroundColor: '#FFFFFF',
            );
            if (rendered == null || rendered.bytes.isEmpty) return;
            rasterBytes = rendered.bytes;
          } finally {
            await page.close();
          }
        } finally {
          await pdf.close();
        }
        _stampSourcePdfBytes = Uint8List.fromList(fileBytes);
      } else {
        rasterBytes = fileBytes;
        _stampSourcePdfBytes = null;
      }

      final sourceDimensions = _decodeImageDimensions(rasterBytes);
      _rawStampBytes = Uint8List.fromList(rasterBytes);
      final cleaned = _makeWhiteTransparent(
        _rawStampBytes!,
        aggressiveness: _aggressiveness,
      );
      if (cleaned == null) return;

      if (!mounted) return;
      setState(() {
        _stampFile = cachedFile;
        _pendingStampPng = cleaned;
        final cleanedDimensions = _decodeImageDimensions(cleaned);
        final dimensions = sourceDimensions ?? cleanedDimensions;
        if (dimensions != null) {
          _pendingStampBaseW = dimensions.width;
          _pendingStampBaseH = dimensions.height;
          _pendingStampScale =
              (140 / _pendingStampBaseW).clamp(_minStampScale, _maxStampScale);
        }
        // Don't auto-enable paste mode on load — just have the stamp ready
        _isPasteMode = false;
        _isMovingStamp = false;
      });
    } catch (_) {
      // Silent fail
    }
  }

  void _updateAggressiveness(double value) {
    final clamped = value.clamp(0.0, 100.0).toDouble();
    setState(() => _aggressiveness = clamped);
    unawaited(_saveAggressiveness(clamped));
    _reprocessCurrentStampForAggressiveness();
  }

  void _reprocessCurrentStampForAggressiveness() {
    if (_rawStampBytes == null) return;
    final cleaned = _makeWhiteTransparent(
      _rawStampBytes!,
      aggressiveness: _aggressiveness,
    );
    if (cleaned == null) return;

    setState(() {
      if (_pendingStampPng != null) {
        _pendingStampPng = cleaned;
      }
      for (final stamp in _placedStamps) {
        stamp.png = cleaned;
      }
    });
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final sizeMb = await file.length() / (1024 * 1024);
    if (sizeMb > 50) {
      _showSnack('PDF is ${sizeMb.toStringAsFixed(1)} MB — keep under 50 MB.');
      return;
    }

    _pdfController?.dispose();
    _pdfController = PdfControllerPinch(document: PdfDocument.openFile(file.path));

    setState(() {
      _pdfFile = file;
      _pageNumber = 1;
      _pageCount = 1;
    });
  }

  Future<void> _pickStampImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
      withData: true,
    );
    if (result == null) return;

    final selected = result.files.single;
    final ext = p.extension(selected.name).toLowerCase();
    final rawFileBytes = selected.bytes ??
        (selected.path == null ? null : await File(selected.path!).readAsBytes());
    final bytes = await _readStampSourceBytes(selected);
    if (bytes == null) return;
    _stampSourcePdfBytes = (ext == '.pdf' && rawFileBytes != null)
        ? Uint8List.fromList(rawFileBytes)
        : null;

    final sourceDimensions = _decodeImageDimensions(bytes);

    _rawStampBytes = Uint8List.fromList(bytes);
    final cleaned = _makeWhiteTransparent(
      _rawStampBytes!,
      aggressiveness: _aggressiveness,
    );
    if (cleaned == null) {
      _showSnack('Could not process stamp image.');
      return;
    }

    setState(() {
      _stampFile = selected.path == null ? null : File(selected.path!);
      _pendingStampPng = cleaned;
      final cleanedDimensions = _decodeImageDimensions(cleaned);
      final dimensions = sourceDimensions ?? cleanedDimensions;
      if (dimensions != null) {
        _pendingStampBaseW = dimensions.width;
        _pendingStampBaseH = dimensions.height;
        _pendingStampScale =
            (140 / _pendingStampBaseW).clamp(_minStampScale, _maxStampScale);
      }
      _isPasteMode = true;
      _isMovingStamp = false;
    });
    // Cache the stamp for next launch
    unawaited(_cacheStampBytes(
      rawFileBytes ?? bytes,
      isPdf: ext == '.pdf',
    ));
    Navigator.of(context).pop(); // close drawer
    _showSnack('Tap on PDF to paste stamp');
  }

  Future<Uint8List?> _readStampSourceBytes(PlatformFile selected) async {
    final ext = p.extension(selected.name).toLowerCase();
    final rawBytes = selected.bytes ??
        (selected.path == null ? null : await File(selected.path!).readAsBytes());
    if (rawBytes == null) return null;

    if (ext != '.pdf') {
      return Uint8List.fromList(rawBytes);
    }

    try {
      final pdf = await PdfDocument.openData(rawBytes);
      try {
        if (pdf.pagesCount < 1) {
          _showSnack('Selected stamp PDF has no pages.');
          return null;
        }

        final page = await pdf.getPage(1);
        try {
          final longestSide = page.width > page.height ? page.width : page.height;
          final scale = (1024.0 / longestSide).clamp(0.25, 1.0);
          final rendered = await page.render(
            width: (page.width * scale).roundToDouble(),
            height: (page.height * scale).roundToDouble(),
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );
          if (rendered == null || rendered.bytes.isEmpty) {
            _showSnack('Could not render first page from stamp PDF.');
            return null;
          }
          return rendered.bytes;
        } finally {
          await page.close();
        }
      } finally {
        await pdf.close();
      }
    } catch (e) {
      _showSnack('Failed to load stamp PDF: $e');
      return null;
    }
  }

  /// Re-renders a stamp PDF at the target export size for high-res output.
  Future<Uint8List?> _renderStampPdfForExport(
    Uint8List pdfBytes,
    double targetW,
    double targetH,
  ) async {
    try {
      final pdf = await PdfDocument.openData(pdfBytes);
      try {
        if (pdf.pagesCount < 1) return null;
        final page = await pdf.getPage(1);
        try {
          // Render at 3x the target PDF-point size for crisp output
          // (PDF points are 72 DPI; 3x gives ~216 DPI equivalent).
          const renderScale = 3.0;
          final renderW = (targetW * renderScale).clamp(100.0, 8192.0);
          final renderH = (targetH * renderScale).clamp(100.0, 8192.0);

          final rendered = await page.render(
            width: renderW.roundToDouble(),
            height: renderH.roundToDouble(),
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );
          if (rendered == null || rendered.bytes.isEmpty) return null;

          // Apply the same white-transparent cleanup
          return _makeWhiteTransparent(
            rendered.bytes,
            aggressiveness: _aggressiveness,
          );
        } finally {
          await page.close();
        }
      } finally {
        await pdf.close();
      }
    } catch (e) {
      return null;
    }
  }

  _ImageDimensions? _decodeImageDimensions(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
      return null;
    }
    return _ImageDimensions(
      decoded.width.toDouble(),
      decoded.height.toDouble(),
    );
  }

  Uint8List? _makeWhiteTransparent(
    Uint8List inputImage, {
    required double aggressiveness,
  }) {
    final source = img.decodeImage(inputImage);
    if (source == null) return null;

    final out = img.Image.from(source);

    // Dynamic near-white thresholding based on border sampling.
    // Aggressiveness (0..100) controls how much borderline pixels are cleared.
    final borderSamples = <int>[];
    var borderRSum = 0;
    var borderGSum = 0;
    var borderBSum = 0;
    var borderCount = 0;
    final maxX = out.width - 1;
    final maxY = out.height - 1;
    final aggr = (aggressiveness / 100).clamp(0.0, 1.0);

    void samplePixel(int x, int y) {
      final px = out.getPixel(x, y);
      final r = px.r.toInt();
      final g = px.g.toInt();
      final b = px.b.toInt();
      borderSamples.add(((r + g + b) / 3).round());
      borderRSum += r;
      borderGSum += g;
      borderBSum += b;
      borderCount++;
    }

    for (var x = 0; x < out.width; x++) {
      samplePixel(x, 0);
      samplePixel(x, maxY);
    }
    for (var y = 1; y < maxY; y++) {
      samplePixel(0, y);
      samplePixel(maxX, y);
    }

    borderSamples.sort();
    final p90Index =
        (borderSamples.length * 0.9).floor().clamp(0, borderSamples.length - 1);
    final borderBrightP90 = borderSamples[p90Index];

    final borderR = (borderRSum / borderCount).toDouble();
    final borderG = (borderGSum / borderCount).toDouble();
    final borderB = (borderBSum / borderCount).toDouble();

    final hardWhiteThreshold =
        (borderBrightP90 + (aggr * 40.0) - 8.0).round().clamp(180, 255);
    final softWindow = (44 - (aggr * 26.0)).round().clamp(10, 52);
    final softWhiteThreshold = (hardWhiteThreshold - softWindow).clamp(140, 246);
    final hardSpreadThreshold = (24 + aggr * 42.0).round().clamp(18, 72);
    final softSpreadThreshold = (hardSpreadThreshold + 16).clamp(28, 92);
    final softFadeMax = (0.72 + aggr * 0.27).clamp(0.72, 0.99);

    // At very high aggressiveness, also remove pixels close to sampled border color
    // (helps gray/beige scan backgrounds that aren't near pure white).
    final useBorderDistanceMode = aggr >= 0.70;
    final borderDistanceThreshold = (18.0 + (aggr - 0.70).clamp(0.0, 0.30) * 180.0)
        .clamp(18.0, 72.0);
    final borderDistanceSoftThreshold =
        (borderDistanceThreshold + 14.0).clamp(26.0, 92.0);
    final borderDistanceFadeMax = (0.65 + aggr * 0.30).clamp(0.65, 0.98);

    for (var y = 0; y < out.height; y++) {
      for (var x = 0; x < out.width; x++) {
        final px = out.getPixel(x, y);
        final r = px.r.toInt();
        final g = px.g.toInt();
        final b = px.b.toInt();
        final a = px.a.toInt();

        final maxRgb = [r, g, b].reduce((a, b) => a > b ? a : b);
        final minRgb = [r, g, b].reduce((a, b) => a < b ? a : b);
        final spread = maxRgb - minRgb;
        final brightness = (r + g + b) / 3.0;

        int outAlpha = a;

        final borderDistance = ((r - borderR).abs() +
                (g - borderG).abs() +
                (b - borderB).abs()) /
            3.0;

        // Hard remove neutral near-white background.
        if (brightness >= hardWhiteThreshold && spread <= hardSpreadThreshold) {
          outAlpha = 0;
        }
        // Soft fade for lighter neutral pixels to avoid harsh edge halos.
        else if (brightness >= softWhiteThreshold &&
            spread <= softSpreadThreshold) {
          final t = ((brightness - softWhiteThreshold) /
                  (hardWhiteThreshold - softWhiteThreshold).clamp(1, 255))
              .clamp(0.0, 1.0);
          outAlpha = (a * (1.0 - t * softFadeMax)).round();
        }

        // Extra mode for non-white paper backgrounds at high aggressiveness.
        if (useBorderDistanceMode && outAlpha > 0) {
          if (borderDistance <= borderDistanceThreshold) {
            outAlpha = 0;
          } else if (borderDistance <= borderDistanceSoftThreshold) {
            final dt = ((borderDistanceSoftThreshold - borderDistance) /
                    (borderDistanceSoftThreshold - borderDistanceThreshold)
                        .clamp(1.0, 255.0))
                .clamp(0.0, 1.0);
            outAlpha = (outAlpha * (1.0 - dt * borderDistanceFadeMax)).round();
          }
        }

        out.setPixelRgba(x, y, r, g, b, outAlpha.clamp(0, 255));
      }
    }

    return Uint8List.fromList(img.encodePng(out));
  }

  Future<void> _combineTwoPdfs() async {
    setState(() => _isCombining = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );
      if (result == null || result.files.length != 2) {
        _showSnack('Select exactly 2 PDF files.');
        return;
      }

      final path1 = result.files[0].path;
      final path2 = result.files[1].path;
      if (path1 == null || path2 == null) {
        _showSnack('Could not read selected PDF paths.');
        return;
      }

      final file1 = File(path1);
      final file2 = File(path2);

      // Load file1 as the base document, then append pages from file2.
      // Avoids the empty-PdfDocument() default-page pitfall that causes
      // null-check errors with createTemplate/insert.
      final doc1Bytes = await file1.readAsBytes();
      final doc2Bytes = await file2.readAsBytes();
      final outDoc = sfpdf.PdfDocument(inputBytes: doc1Bytes);
      final doc2 = sfpdf.PdfDocument(inputBytes: doc2Bytes);
      try {
        for (int i = 0; i < doc2.pages.count; i++) {
          final srcPage = doc2.pages[i];
          final pageSize = srcPage.size;
          final template = srcPage.createTemplate();
          final dstPage = outDoc.pages.add();
          dstPage.graphics.drawPdfTemplate(
            template,
            Offset.zero,
            Size(pageSize.width, pageSize.height),
          );
        }
      } finally {
        doc2.dispose();
      }

      final outBytes = Uint8List.fromList(await outDoc.save());
      outDoc.dispose();

      final outFile = _buildUniqueSiblingFile(
        file1,
        suffix: '_${p.basenameWithoutExtension(file2.path)}_combined',
      );
      await outFile.writeAsBytes(outBytes, flush: true);
      _showSnack('Saved: ${_displaySavedPath(file1, outFile)}');
    } catch (e) {
      _showSnack('Failed to combine PDFs: $e');
    } finally {
      if (mounted) setState(() => _isCombining = false);
    }
  }

  Future<void> _exportStampedPdf() async {
    if (_pdfFile == null || _placedStamps.isEmpty) {
      _showSnack('Pick PDF and place at least one stamp first.');
      return;
    }
    setState(() => _isExporting = true);
    try {
      final pdfBytes = await _pdfFile!.readAsBytes();
      final document = sfpdf.PdfDocument(inputBytes: pdfBytes);
      final totalPages = document.pages.count;
      final currentPageIndex = (_pageNumber - 1).clamp(0, totalPages - 1);

      final page = document.pages[currentPageIndex];
      final pageSize = page.size;

      // Get actual preview widget dimensions.
      final stackContext = _previewStackKey.currentContext;
      final renderBox = stackContext?.findRenderObject() as RenderBox?;
      final previewSize = renderBox?.size ?? MediaQuery.of(context).size;
      final previewW = previewSize.width;
      final previewH = previewSize.height;

      // Compute how PdfViewPinch renders the page (contain-fit).
      final pageAspect = pageSize.width / pageSize.height;
      final previewAspect = previewW / previewH;

      double renderedW, renderedH, offsetX, offsetY;
      if (pageAspect > previewAspect) {
        // Page wider than preview → fit by width
        renderedW = previewW;
        renderedH = previewW / pageAspect;
        offsetX = 0;
        offsetY = (previewH - renderedH) / 2;
      } else {
        // Page taller than preview → fit by height
        renderedH = previewH;
        renderedW = previewH * pageAspect;
        offsetX = (previewW - renderedW) / 2;
        offsetY = 0;
      }

      // Single uniform scale from rendered-page pixels to PDF points.
      final pdfScale = pageSize.width / renderedW;

      for (final stamp in _placedStamps) {
        final pdfX = (stamp.x - offsetX) * pdfScale;
        final pdfY = (stamp.y - offsetY) * pdfScale;
        final pdfW = stamp.w * pdfScale;
        final pdfH = stamp.h * pdfScale;

        // Use high-res re-render for PDF-sourced stamps.
        Uint8List stampPng = stamp.png;
        if (_stampSourcePdfBytes != null) {
          stampPng = await _renderStampPdfForExport(
            _stampSourcePdfBytes!,
            pdfW,
            pdfH,
          ) ?? stamp.png;
        }

        final state = page.graphics.save();
        page.graphics.translateTransform(pdfX + (pdfW / 2), pdfY + (pdfH / 2));
        page.graphics.rotateTransform(stamp.rotationDeg);
        page.graphics.translateTransform(-(pdfW / 2), -(pdfH / 2));
        page.graphics.setTransparency(1.0);
        page.graphics.drawImage(
          sfpdf.PdfBitmap(stampPng),
          Rect.fromLTWH(0, 0, pdfW, pdfH),
        );
        page.graphics.restore(state);
      }

      final outputBytes = Uint8List.fromList(await document.save());
      document.dispose();

      final outFile = _buildUniqueSiblingFile(_pdfFile!, suffix: '_stamped');
      await outFile.writeAsBytes(outputBytes, flush: true);
      _showSnack('Saved: ${_displaySavedPath(_pdfFile!, outFile)}');
    } catch (e) {
      _showSnack('Failed to export: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  File _buildUniqueSiblingFile(
    File source, {
    required String suffix,
    String extension = '.pdf',
  }) {
    final dir = _preferredOutputDir(source);
    final base = p.basenameWithoutExtension(source.path);
    final preferred = File(p.join(dir.path, '$base$suffix$extension'));
    if (!preferred.existsSync()) return preferred;

    var index = 1;
    while (true) {
      final candidate =
          File(p.join(dir.path, '$base$suffix($index)$extension'));
      if (!candidate.existsSync()) return candidate;
      index++;
    }
  }

  Directory _preferredOutputDir(File source) {
    final sourcePath = source.path;
    final isAppCachePath = sourcePath.contains('/cache/') ||
        sourcePath.contains('/Android/data/');

    if (Platform.isAndroid && isAppCachePath) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (downloadsDir.existsSync()) {
        return downloadsDir;
      }
    }

    return source.parent;
  }

  String _displaySavedPath(File source, File outFile) {
    return outFile.path;
  }

  // ── Gesture handlers ────────────────────────────────────────────────────────

  void _handlePreviewTapDown(TapDownDetails details) {
    if (!_isPasteMode || _pendingStampPng == null) return;
    _addStampAt(details.localPosition);
  }

  void _addStampAt(Offset pos) {
    setState(() {
      final pendingDimensions =
          _pendingStampPng == null ? null : _decodeImageDimensions(_pendingStampPng!);
      final baseWidth = pendingDimensions?.width ?? _pendingStampBaseW;
      final baseHeight = pendingDimensions?.height ?? _pendingStampBaseH;
      final stamp = _PlacedStamp(
        png: _pendingStampPng!,
        x: (pos.dx - (_pendingStampW / 2)).clamp(0.0, 10000.0),
        y: (pos.dy - (_pendingStampH / 2)).clamp(0.0, 10000.0),
        baseWidth: baseWidth,
        baseHeight: baseHeight,
        scale: _pendingStampScale,
        rotationDeg: _rotationDeg,
      );
      _placedStamps.add(stamp);
      _selectedStampIndex = _placedStamps.length - 1;
      _isMovingStamp = false;
    });
    _showSnack('Stamp added');
  }

  void _selectStampByIndex(int index) {
    if (index < 0 || index >= _placedStamps.length) return;
    final stamp = _placedStamps[index];
    setState(() {
      _selectedStampIndex = index;
      _rotationDeg = stamp.rotationDeg;
    });
  }

  double get _currentStampSize => _selectedStamp?.w ?? _pendingStampW;

  void _updateCurrentStampSize(double size) {
    final clamped = size.clamp(40.0, 380.0).toDouble();
    setState(() {
      final selected = _selectedStamp;
      if (selected != null) {
        selected.scale =
            (clamped / selected.baseWidth).clamp(_minStampScale, _maxStampScale);
      } else {
        _pendingStampScale = (clamped / _pendingStampBaseW)
            .clamp(_minStampScale, _maxStampScale)
            .toDouble();
      }
    });
  }

  void _handlePreviewPanStart(DragStartDetails details) {
    if (!_isMovingStamp) return;
    final selected = _selectedStamp;
    if (selected == null) return;

    final stackContext = _previewStackKey.currentContext;
    final renderBox = stackContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localInPreview = renderBox.globalToLocal(details.globalPosition);
    if (!_isPointOnSelectedStamp(localInPreview)) {
      _movingPointerOffset = null;
      _showSnack('Start dragging on the selected stamp');
      return;
    }
    _movingPointerOffset = localInPreview - Offset(selected.x, selected.y);
  }

  void _handlePreviewPanUpdate(DragUpdateDetails details) {
    if (!_isMovingStamp || _movingPointerOffset == null) return;
    final stackContext = _previewStackKey.currentContext;
    final renderBox = stackContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localInPreview = renderBox.globalToLocal(details.globalPosition);
    _repositionSelectedStampWithOffset(localInPreview);
  }

  void _handlePreviewPanEnd(DragEndDetails details) {
    _movingPointerOffset = null;
  }

  void _handlePreviewPanCancel() {
    _movingPointerOffset = null;
  }

  void _repositionSelectedStampWithOffset(Offset pos) {
    final selected = _selectedStamp;
    if (selected == null) return;
    final offset = _movingPointerOffset ?? Offset(selected.w / 2, selected.h / 2);
    setState(() {
      selected.x = (pos.dx - offset.dx).clamp(0.0, 10000.0);
      selected.y = (pos.dy - offset.dy).clamp(0.0, 10000.0);
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleStampTap() {
    if (_selectedStamp == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stamp Options', style: TextStyle(color: _kTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_with, color: _kAccentPrimary),
              title: const Text('Move', style: TextStyle(color: _kTextPrimary)),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _isMovingStamp = true;
                });
                _showSnack('Drag selected stamp to reposition');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete selected', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(ctx).pop();
                final idx = _selectedStampIndex;
                if (idx == null || idx < 0 || idx >= _placedStamps.length) return;
                setState(() {
                  _placedStamps.removeAt(idx);
                  if (_placedStamps.isEmpty) {
                    _selectedStampIndex = null;
                    _isMovingStamp = false;
                  } else {
                    _selectedStampIndex =
                        (_placedStamps.length - 1).clamp(0, _placedStamps.length - 1).toInt();
                    _isMovingStamp = false;
                  }
                });
                _showSnack('Stamp removed');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Drawer (burger menu) ──────────────────────────────────────────────────

  Widget _buildDrawer() {
    final hasAnyStamp = _activePreviewStampPng != null;
    final canPlaceStamp = _pdfFile != null && (_selectedStamp != null || _isPasteMode);

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(gradient: _kBgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // ── Header
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'PDF Stamp',
                  style: TextStyle(
                    color: _kTextPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // ── File actions
              _GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Files',
                        style: TextStyle(
                            color: _kTextSecond,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1)),
                    const SizedBox(height: 10),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.picture_as_pdf_outlined,
                          color: _kAccentPrimary, size: 20),
                      title: Text(
                        _pdfFile != null
                            ? p.basename(_pdfFile!.path)
                            : 'Pick PDF',
                        style: const TextStyle(
                            color: _kTextPrimary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickPdf();
                      },
                    ),
                    ListTile(
                      dense: true,
                      leading: Icon(
                        _isPasteMode
                            ? Icons.touch_app_outlined
                            : Icons.image_outlined,
                        color: _kAccentPrimary,
                        size: 20,
                      ),
                      title: Text(
                        _isPasteMode
                            ? 'Tap PDF to paste'
                            : _stampFile != null
                                ? p.basename(_stampFile!.path)
                                : 'Pick Stamp',
                        style: const TextStyle(
                            color: _kTextPrimary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: _isPasteMode ? null : _pickStampImage,
                    ),
                    if (_pendingStampPng != null)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.add_circle_outline,
                            color: _kAccentSecond, size: 20),
                        title: const Text(
                          'Tap to Stamp (keep on)',
                          style: TextStyle(color: _kTextPrimary, fontSize: 13),
                        ),
                        subtitle: const Text(
                          'Tap on PDF to add multiple stamps',
                          style: TextStyle(color: _kTextSecond, fontSize: 11),
                        ),
                        trailing: Switch(
                          value: _isPasteMode,
                          onChanged: (v) => setState(() {
                            _isPasteMode = v;
                            if (!v) _isMovingStamp = false;
                          }),
                        ),
                      ),
                    if (_placedStamps.isNotEmpty)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.layers_outlined,
                            color: _kAccentPrimary, size: 20),
                        title: Text(
                          'Stamps placed: ${_placedStamps.length}',
                          style: const TextStyle(
                              color: _kTextPrimary, fontSize: 13),
                        ),
                      ),
                    if (_placedStamps.isNotEmpty)
                      ...List<Widget>.generate(_placedStamps.length, (i) {
                        final selected = i == _selectedStampIndex;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selected ? _kAccentSecond : _kTextSecond,
                            size: 18,
                          ),
                          title: Text(
                            'Stamp ${i + 1}',
                            style: TextStyle(
                              color: selected ? _kAccentSecond : _kTextPrimary,
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          onTap: () => _selectStampByIndex(i),
                        );
                      }),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Stamp controls
              _GlassCard(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune,
                            size: 14, color: _kAccentPrimary),
                        const SizedBox(width: 6),
                        const Text('Stamp Controls',
                            style: TextStyle(
                                color: _kTextSecond,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1)),
                        if (_isMovingStamp) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              setState(() => _isMovingStamp = false);
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: _kAccentPrimary.withOpacity(0.25),
                                border: Border.all(color: _kAccentPrimary),
                              ),
                              child: const Text('Done',
                                  style: TextStyle(
                                      color: _kAccentPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    _LabelledSlider(
                      label: 'Size',
                      value: _currentStampSize,
                      min: 40,
                      max: 380,
                      onChanged:
                          canPlaceStamp ? _updateCurrentStampSize : null,
                    ),
                    _LabelledSlider(
                      label: 'Rotate',
                      value: _rotationDeg,
                      min: -180,
                      max: 180,
                      onChanged: canPlaceStamp
                          ? (v) => setState(() {
                              _rotationDeg = v;
                              final selected = _selectedStamp;
                              if (selected != null) selected.rotationDeg = v;
                            })
                          : null,
                    ),
                    _LabelledSlider(
                      label: 'Clean',
                      value: _aggressiveness,
                      min: 0,
                      max: 100,
                      onChanged: _rawStampBytes != null
                          ? _updateAggressiveness
                          : null,
                    ),
                    if (hasAnyStamp)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 6),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0x14000000),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kGlassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preview • Clean ${_aggressiveness.round()}%',
                                style: const TextStyle(
                                  color: _kTextSecond,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: SizedBox(
                                    width: 120,
                                    height: 52,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        const CustomPaint(
                                          painter: _CheckerboardPainter(
                                              cellSize: 8),
                                        ),
                                        Center(
                                          child: Image.memory(
                                            _activePreviewStampPng!,
                                            width: 120,
                                            height: 52,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Actions
              _GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Actions',
                        style: TextStyle(
                            color: _kTextSecond,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1)),
                    const SizedBox(height: 10),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.merge_outlined,
                          color: _kAccentPrimary, size: 20),
                      title: Text(
                        _isCombining ? 'Combining…' : 'Combine 2 PDFs',
                        style: const TextStyle(
                            color: _kTextPrimary, fontSize: 13),
                      ),
                      onTap: _isCombining
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _combineTwoPdfs();
                            },
                    ),
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.file_download_outlined,
                          color: _isExporting
                              ? _kTextSecond
                              : _kAccentPrimary,
                          size: 20),
                      title: Text(
                        _isExporting ? 'Exporting…' : 'Export Stamped PDF',
                        style: TextStyle(
                          color: _isExporting ? _kTextSecond : _kTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: _isExporting
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _exportStampedPdf();
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x88302B63), Color(0x00302B63)],
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'PDF Stamp',
          style: TextStyle(
            color: _kTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          // Page indicator pill in the AppBar
          if (_pdfController != null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0x22FFFFFF),
                  border: Border.all(color: _kGlassBorder),
                ),
                child: Text(
                  'Page $_pageNumber / $_pageCount',
                  style: const TextStyle(
                    color: _kTextSecond,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // Moving mode indicator
          if (_isMovingStamp)
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _isMovingStamp = false),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _kAccentPrimary.withOpacity(0.25),
                    border: Border.all(color: _kAccentPrimary),
                  ),
                  child: const Text(
                    'Done Moving',
                    style: TextStyle(
                      color: _kAccentPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          // Paste mode indicator
          if (_isPasteMode)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _kAccentSecond.withOpacity(0.25),
                  border: Border.all(color: _kAccentSecond),
                ),
                child: const Text(
                  'Tap to Stamp ON',
                  style: TextStyle(
                    color: _kAccentSecond,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (_placedStamps.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0x22FFFFFF),
                  border: Border.all(color: _kGlassBorder),
                ),
                child: Text(
                  'Stamps ${_placedStamps.length}',
                  style: const TextStyle(
                    color: _kTextSecond,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: const BoxDecoration(gradient: _kBgGradient),
        child: SafeArea(
          child: _buildPdfArea(),
        ),
      ),
    );
  }

  Widget _buildPdfArea() {
    if (_pdfController == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_outlined, size: 64, color: _kTextSecond),
            SizedBox(height: 12),
            Text(
              'Open the menu to pick a PDF',
              style: TextStyle(color: _kTextSecond, fontSize: 15),
            ),
          ],
        ),
      );
    }

    // When in paste mode, wrap with tap handler.
    // Otherwise PdfViewPinch handles all gestures (scroll/zoom) directly.
    final pdfView = PdfViewPinch(
      controller: _pdfController!,
      onPageChanged: (page) => setState(() => _pageNumber = page),
      onDocumentLoaded: (doc) {
        setState(() => _pageCount = doc.pagesCount);
      },
    );

    final preview = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _isPasteMode ? _handlePreviewTapDown : null,
      child: pdfView,
    );

    return Stack(
      key: _previewStackKey,
      fit: StackFit.expand,
      children: [
        preview,
        for (var i = 0; i < _placedStamps.length; i++)
          _buildPlacedStamp(i, _placedStamps[i]),
      ],
    );
  }

  Widget _buildPlacedStamp(int index, _PlacedStamp stamp) {
    final selected = index == _selectedStampIndex;

    return Positioned(
      left: stamp.x,
      top: stamp.y,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _selectStampByIndex(index);
          if (!_isMovingStamp) {
            _handleStampTap();
          }
        },
        onPanStart: _isMovingStamp && selected ? _handlePreviewPanStart : null,
        onPanUpdate: _isMovingStamp && selected ? _handlePreviewPanUpdate : null,
        onPanEnd: _isMovingStamp && selected ? _handlePreviewPanEnd : null,
        onPanCancel: _isMovingStamp && selected ? _handlePreviewPanCancel : null,
        child: Transform.rotate(
          angle: stamp.rotationDeg * 3.1415926535 / 180.0,
          child: Opacity(
            opacity: _isMovingStamp && selected ? 0.65 : 1.0,
            child: Container(
              decoration: selected
                  ? BoxDecoration(
                      border: Border.all(color: _kAccentSecond, width: 1.2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Image.memory(
                stamp.png,
                width: stamp.w,
                height: stamp.h,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
