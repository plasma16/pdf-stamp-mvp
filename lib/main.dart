import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';


import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
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
  Uint8List? _cleanedStampPng;

  PdfControllerPinch? _pdfController;
  final GlobalKey _previewStackKey = GlobalKey();

  int _pageNumber = 1;
  int _pageCount = 1;

  double _stampX = 120;
  double _stampY = 180;
  double _stampW = 140;
  double _stampH = 90;
  double _rotationDeg = 0;
  double _aggressiveness = _kDefaultAggressiveness;

  bool _isMovingStamp = false;
  bool _isPasteMode = false;
  Uint8List? _pendingStampPng; // held until user taps to place

  bool _isExporting = false;
  bool _isCombining = false;

  Offset? _movingPointerOffset;

  Rect get _stampBounds => Rect.fromLTWH(_stampX, _stampY, _stampW, _stampH);
  bool _isPointOnStamp(Offset pos) => _stampBounds.contains(pos);
  Uint8List? get _activePreviewStampPng => _pendingStampPng ?? _cleanedStampPng;

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
  }

  Future<void> _saveAggressiveness(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kAggressivenessPrefKey, value);
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
      if (_isPasteMode && _pendingStampPng != null) {
        _pendingStampPng = cleaned;
      } else if (_cleanedStampPng != null) {
        _cleanedStampPng = cleaned;
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
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null) return;

    final bytes = result.files.single.bytes ??
        await File(result.files.single.path!).readAsBytes();

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
      _stampFile = result.files.single.path == null
          ? null
          : File(result.files.single.path!);
      _pendingStampPng = cleaned;
      _isPasteMode = true;
      _isMovingStamp = false;
    });
    Navigator.of(context).pop(); // close drawer
    _showSnack('Tap on PDF to paste stamp');
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
      final outDoc = sfpdf.PdfDocument();
      try {
        final doc1 = sfpdf.PdfDocument(inputBytes: await file1.readAsBytes());
        final doc2 = sfpdf.PdfDocument(inputBytes: await file2.readAsBytes());
        try {
          void copyPages(sfpdf.PdfDocument source) {
            for (int i = 0; i < source.pages.count; i++) {
              final srcPage = source.pages[i];
              final pageSize = srcPage.size;
              final dstPage = outDoc.pages.insert(
                outDoc.pages.count,
                Size(pageSize.width, pageSize.height),
              );
              dstPage.graphics.drawPdfTemplate(
                srcPage.createTemplate(),
                Offset.zero,
                Size(pageSize.width, pageSize.height),
              );
            }
          }
          copyPages(doc1);
          copyPages(doc2);
        } finally {
          doc1.dispose();
          doc2.dispose();
        }

        final outBytes = Uint8List.fromList(await outDoc.save());
        final outFile = _buildUniqueSiblingFile(
          file1,
          suffix: '_${p.basenameWithoutExtension(file2.path)}_combined',
        );
        await outFile.writeAsBytes(outBytes, flush: true);
        _showSnack('Saved: ${_displaySavedPath(file1, outFile)}');
      } finally {
        outDoc.dispose();
      }
    } catch (e) {
      _showSnack('Failed to combine PDFs: $e');
    } finally {
      if (mounted) setState(() => _isCombining = false);
    }
  }

  Future<void> _exportStampedPdf() async {
    if (_pdfFile == null || _cleanedStampPng == null) {
      _showSnack('Pick both a PDF and a stamp first.');
      return;
    }
    setState(() => _isExporting = true);
    try {
      final pdfBytes = await _pdfFile!.readAsBytes();
      final document = sfpdf.PdfDocument(inputBytes: pdfBytes);
      final totalPages = document.pages.count;
      final currentPageIndex = (_pageNumber - 1).clamp(0, totalPages - 1);

      for (final idx in [currentPageIndex]) {
        final page = document.pages[idx];
        final pageSize = page.size;
        final previewW = MediaQuery.of(context).size.width;
        final previewH = MediaQuery.of(context).size.height;
        final scaleX = pageSize.width / previewW;
        final scaleY = pageSize.height / previewH;

        final x = _stampX * scaleX;
        final y = _stampY * scaleY;
        final w = _stampW * scaleX;
        final h = _stampH * scaleY;

        final state = page.graphics.save();
        page.graphics.translateTransform(x + (w / 2), y + (h / 2));
        page.graphics.rotateTransform(_rotationDeg);
        page.graphics.translateTransform(-(w / 2), -(h / 2));
        page.graphics.setTransparency(1.0);
        page.graphics.drawImage(
            sfpdf.PdfBitmap(_cleanedStampPng!), Rect.fromLTWH(0, 0, w, h));
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
    final sourcePath = source.path;
    final isAppCachePath = sourcePath.contains('/cache/') ||
        sourcePath.contains('/Android/data/');
    if (Platform.isAndroid && isAppCachePath) {
      return '${outFile.path} (saved to Downloads because Android picker returned cache path)';
    }
    return outFile.path;
  }

  // ── Gesture handlers ────────────────────────────────────────────────────────

  void _handlePreviewTapDown(TapDownDetails details) {
    if (!_isPasteMode || _pendingStampPng == null) return;
    setState(() {
      _cleanedStampPng = _pendingStampPng;
      _pendingStampPng = null;
      _isPasteMode = false;
      _isMovingStamp = false;
    });
    _repositionStampTo(details.localPosition);
    _showSnack('Stamp pasted');
  }

  void _handlePreviewPanStart(DragStartDetails details) {
    if (!_isMovingStamp) return;
    final stackContext = _previewStackKey.currentContext;
    final renderBox =
        stackContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final globalPos = details.globalPosition;
    final localInPreview = renderBox.globalToLocal(globalPos);
    if (!_isPointOnStamp(localInPreview)) {
      _movingPointerOffset = null;
      _showSnack('Start dragging on the stamp to move it');
      return;
    }
    _movingPointerOffset = localInPreview - Offset(_stampX, _stampY);
  }

  void _handlePreviewPanUpdate(DragUpdateDetails details) {
    if (!_isMovingStamp || _movingPointerOffset == null) return;
    final stackContext = _previewStackKey.currentContext;
    final renderBox = stackContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localInPreview = renderBox.globalToLocal(details.globalPosition);
    _repositionStampWithOffset(localInPreview);
  }

  void _handlePreviewPanEnd(DragEndDetails details) {
    _movingPointerOffset = null;
  }

  void _handlePreviewPanCancel() {
    _movingPointerOffset = null;
  }

  void _repositionStampWithOffset(Offset pos) {
    final offset = _movingPointerOffset ?? Offset(_stampW / 2, _stampH / 2);
    setState(() {
      _stampX = (pos.dx - offset.dx).clamp(0.0, 10000.0);
      _stampY = (pos.dy - offset.dy).clamp(0.0, 10000.0);
    });
  }

  void _repositionStampTo(Offset pos) {
    setState(() {
      _stampX = (pos.dx - (_stampW / 2)).clamp(0.0, 10000.0);
      _stampY = (pos.dy - (_stampH / 2)).clamp(0.0, 10000.0);
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleStampTap(TapDownDetails details) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stamp Options',
            style: TextStyle(color: _kTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_with, color: _kAccentPrimary),
              title: const Text('Move',
                  style: TextStyle(color: _kTextPrimary)),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _isMovingStamp = true;
                  _isPasteMode = false;
                });
                _showSnack('Drag to reposition stamp');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _rawStampBytes = null;
                  _cleanedStampPng = null;
                  _pendingStampPng = null;
                  _stampFile = null;
                  _isPasteMode = false;
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
    final canPlaceStamp = _pdfFile != null && hasAnyStamp;

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
                      label: 'Width',
                      value: _stampW,
                      min: 40,
                      max: 380,
                      onChanged: canPlaceStamp
                          ? (v) => setState(() => _stampW = v)
                          : null,
                    ),
                    _LabelledSlider(
                      label: 'Height',
                      value: _stampH,
                      min: 25,
                      max: 260,
                      onChanged: canPlaceStamp
                          ? (v) => setState(() => _stampH = v)
                          : null,
                    ),
                    _LabelledSlider(
                      label: 'Rotate',
                      value: _rotationDeg,
                      min: -180,
                      max: 180,
                      onChanged: canPlaceStamp
                          ? (v) => setState(() => _rotationDeg = v)
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
                  'Tap to Paste',
                  style: TextStyle(
                    color: _kAccentSecond,
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

    // When in paste or moving mode, wrap with gesture detector.
    // When idle, PdfViewPinch handles all gestures (scroll/zoom) directly.
    final pdfView = PdfViewPinch(
      controller: _pdfController!,
      onPageChanged: (page) => setState(() => _pageNumber = page),
      onDocumentLoaded: (doc) {
        setState(() => _pageCount = doc.pagesCount);
      },
    );

    // Always keep the same widget tree structure so PdfViewPinch is not
    // rebuilt (which loses the loaded document). Conditionally wire callbacks.
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
        if (_cleanedStampPng != null)
          Positioned(
            left: _stampX,
            top: _stampY,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: _isMovingStamp ? null : _handleStampTap,
              onPanStart: _isMovingStamp ? _handlePreviewPanStart : null,
              onPanUpdate: _isMovingStamp ? _handlePreviewPanUpdate : null,
              onPanEnd: _isMovingStamp ? _handlePreviewPanEnd : null,
              onPanCancel: _isMovingStamp ? _handlePreviewPanCancel : null,
              child: Transform.rotate(
                angle: _rotationDeg * 3.1415926535 / 180.0,
                child: Opacity(
                  opacity: _isMovingStamp ? 0.65 : 1.0,
                  child: Image.memory(
                    _cleanedStampPng!,
                    width: _stampW,
                    height: _stampH,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
