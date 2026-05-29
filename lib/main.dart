import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
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
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(_kAccentPrimary),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? _kAccentPrimary.withOpacity(0.5)
                : const Color(0x44FFFFFF),
          ),
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
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0x22FFFFFF)),
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

// ── Glass action button ───────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.loading = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primary ? _kAccentPrimary.withOpacity(0.7) : _kGlassBorder,
            ),
            gradient: primary
                ? const LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFF00D2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0x2BFFFFFF), Color(0x10FFFFFF)],
                  ),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: _kAccentPrimary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Label chip ────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0x18FFFFFF),
        border: Border.all(color: const Color(0x30FFFFFF)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: const TextStyle(
                color: _kTextSecond,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: _kTextPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
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
          width: 68,
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
          width: 38,
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

// ── Main page ─────────────────────────────────────────────────────────────────
class StampHomePage extends StatefulWidget {
  const StampHomePage({super.key});

  @override
  State<StampHomePage> createState() => _StampHomePageState();
}

class _StampHomePageState extends State<StampHomePage> {
  File? _pdfFile;
  File? _stampFile;
  Uint8List? _cleanedStampPng;

  PdfControllerPinch? _pdfController;

  int _pageNumber = 1;
  int _pageCount = 1;

  double _stampX = 120;
  double _stampY = 180;
  double _stampW = 140;
  double _stampH = 90;
  double _rotationDeg = 0;

  bool _applyAllPages = false;
  bool _isMovingStamp = false;
  bool _showDeleteConfirm = false;
  final TextEditingController _startPageCtl = TextEditingController(text: '1');
  final TextEditingController _endPageCtl   = TextEditingController(text: '1');

  bool _isExporting = false;
  bool _isCombining = false;

  @override
  void dispose() {
    _pdfController?.dispose();
    _startPageCtl.dispose();
    _endPageCtl.dispose();
    super.dispose();
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
      _startPageCtl.text = '1';
      _endPageCtl.text = '1';
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

    final cleaned = _makeWhiteTransparent(bytes);
    if (cleaned == null) {
      _showSnack('Could not process stamp image.');
      return;
    }

    setState(() {
      _stampFile  = result.files.single.path == null ? null : File(result.files.single.path!);
      _cleanedStampPng = cleaned;
    });
  }

  Uint8List? _makeWhiteTransparent(Uint8List inputImage) {
    final source = img.decodeImage(inputImage);
    if (source == null) return null;

    final out = img.Image.from(source);
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

        int outAlpha = a;
        if (r > 245 && g > 245 && b > 245 && spread < 15) {
          outAlpha = 0;
        } else if (r > 230 && g > 230 && b > 230 && spread < 20) {
          final brightness = (r + g + b) / 3.0;
          final t = ((brightness - 230) / 15).clamp(0.0, 1.0);
          outAlpha = (a * (1.0 - t * 0.85)).round();
        }
        out.setPixelRgba(x, y, r, g, b, outAlpha);
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
        final dir   = file1.parent;
        final base1 = p.basenameWithoutExtension(file1.path);
        final base2 = p.basenameWithoutExtension(file2.path);
        final outFile = File(p.join(dir.path, '${base1}_${base2}_combined.pdf'));
        await outFile.writeAsBytes(outBytes, flush: true);
        _showSnack('Saved: ${outFile.path}');
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
      final pdfBytes  = await _pdfFile!.readAsBytes();
      final document  = sfpdf.PdfDocument(inputBytes: pdfBytes);
      final pageIndexes = _buildPageIndexes(document.pages.count);
      if (pageIndexes.isEmpty) {
        document.dispose();
        _showSnack('No valid pages selected.');
        return;
      }

      for (final idx in pageIndexes) {
        final page     = document.pages[idx];
        final pageSize = page.size;
        final previewW = MediaQuery.of(context).size.width - 32;
        final previewH = (MediaQuery.of(context).size.height * 0.55).clamp(1, 2000).toDouble();
        final scaleX = pageSize.width  / previewW;
        final scaleY = pageSize.height / previewH;

        final x = _stampX * scaleX;
        final y = _stampY * scaleY;
        final w = _stampW * scaleX;
        final h = _stampH * scaleY;

        final state = page.graphics.save();
        page.graphics.translateTransform(x + (w / 2), y + (h / 2));
        page.graphics.rotateTransform(_rotationDeg);
        page.graphics.translateTransform(-(w / 2), -(h / 2));
        page.graphics.drawImage(sfpdf.PdfBitmap(_cleanedStampPng!), Rect.fromLTWH(0, 0, w, h));
        page.graphics.restore(state);
      }

      final outputBytes = Uint8List.fromList(await document.save());
      document.dispose();

      final dir     = _pdfFile!.parent;
      final base    = p.basenameWithoutExtension(_pdfFile!.path);
      final outFile = File(p.join(dir.path, '${base}_stamped.pdf'));
      await outFile.writeAsBytes(outputBytes, flush: true);
      _showSnack('Saved: ${outFile.path}');
    } catch (e) {
      _showSnack('Failed to export: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  List<int> _buildPageIndexes(int totalPages) {
    if (_applyAllPages) return List<int>.generate(totalPages, (i) => i);
    final start = int.tryParse(_startPageCtl.text.trim()) ?? _pageNumber;
    final end   = int.tryParse(_endPageCtl.text.trim())   ?? _pageNumber;
    final s    = start.clamp(1, totalPages);
    final e    = end.clamp(1, totalPages);
    final from = s <= e ? s : e;
    final to   = s <= e ? e : s;
    return [for (var pp = from; pp <= to; pp++) pp - 1];
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleStampTap(TapDownDetails details) {
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
                setState(() => _isMovingStamp = true);
                _showSnack('Drag to reposition stamp');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _cleanedStampPng = null;
                  _stampFile = null;
                });
                _showSnack('Stamp removed');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canPlaceStamp = _pdfFile != null && _cleanedStampPng != null;
    final mediaQuery    = MediaQuery.of(context);
    final bottomInset   = mediaQuery.padding.bottom > mediaQuery.viewPadding.bottom
        ? mediaQuery.padding.bottom
        : mediaQuery.viewPadding.bottom;
    final safeBodyHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        bottomInset -
        kToolbarHeight;
    final previewHeight = (safeBodyHeight * 0.55).clamp(200.0, 700.0).toDouble();

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
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: _kBgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Action buttons ─────────────────────────────────────────
                _GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _GlassButton(
                        label: 'Pick PDF',
                        icon: Icons.picture_as_pdf_outlined,
                        onPressed: _pickPdf,
                      ),
                      _GlassButton(
                        label: 'Pick Stamp',
                        icon: Icons.image_outlined,
                        onPressed: _pickStampImage,
                      ),
                      _GlassButton(
                        label: _isCombining ? 'Combining…' : 'Combine 2',
                        icon: Icons.merge_outlined,
                        loading: _isCombining,
                        onPressed: _isCombining ? null : _combineTwoPdfs,
                      ),
                      _GlassButton(
                        label: _isExporting ? 'Exporting…' : 'Export',
                        icon: Icons.file_download_outlined,
                        primary: true,
                        loading: _isExporting,
                        onPressed: _isExporting ? null : _exportStampedPdf,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── File info chips ────────────────────────────────────────
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      label: 'PDF',
                      value: _pdfFile != null
                          ? p.basename(_pdfFile!.path)
                          : 'none',
                    ),
                    _InfoChip(
                      label: 'Stamp',
                      value: _stampFile != null
                          ? p.basename(_stampFile!.path)
                          : _cleanedStampPng != null ? 'loaded' : 'none',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── PDF preview ────────────────────────────────────────────
                _GlassCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: previewHeight,
                      child: _pdfController != null
                          ? Stack(
                              children: [
                                Scrollbar(
                                  thumbVisibility: true,
                                  interactive: true,
                                  child: PdfViewPinch(
                                    controller: _pdfController!,
                                    onPageChanged: (page) =>
                                        setState(() => _pageNumber = page),
                                    onDocumentLoaded: (doc) {
                                      setState(() {
                                        _pageCount = doc.pagesCount;
                                        _startPageCtl.text = '$_pageNumber';
                                        _endPageCtl.text   = '$_pageNumber';
                                      });
                                    },
                                  ),
                                ),
                                if (_cleanedStampPng != null)
                                  Positioned(
                                    left: _stampX,
                                    top:  _stampY,
                                    child: GestureDetector(
                                      onPanUpdate: (d) {
                                        if (_isMovingStamp) {
                                          setState(() {
                                            _stampX = (_stampX + d.delta.dx).clamp(0.0, 10000.0);
                                            _stampY = (_stampY + d.delta.dy).clamp(0.0, 10000.0);
                                          });
                                        }
                                      },
                                      onTapDown: _handleStampTap,
                                      child: Transform.rotate(
                                        angle: _rotationDeg * 3.1415926535 / 180.0,
                                        child: Opacity(
                                          opacity: _isMovingStamp ? 0.65 : 1.0,
                                          child: Image.memory(
                                            _cleanedStampPng!,
                                            width:  _stampW,
                                            height: _stampH,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.picture_as_pdf_outlined,
                                      size: 48, color: _kTextSecond),
                                  SizedBox(height: 10),
                                  Text(
                                    'Pick a PDF to preview',
                                    style: TextStyle(
                                      color: _kTextSecond,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Page indicator ─────────────────────────────────────────
                if (_pdfController != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

                const SizedBox(height: 12),

                // ── Page range + apply-all ─────────────────────────────────
                _GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: SwitchListTile.adaptive(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'All pages',
                            style: TextStyle(color: _kTextPrimary, fontSize: 13),
                          ),
                          value: _applyAllPages,
                          onChanged: canPlaceStamp
                              ? (v) => setState(() => _applyAllPages = v)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _startPageCtl,
                          enabled: !_applyAllPages,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: _kTextPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Start',
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _endPageCtl,
                          enabled: !_applyAllPages,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: _kTextPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'End',
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Stamp controls ─────────────────────────────────────────
                _GlassCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune, size: 16, color: _kAccentPrimary),
                          const SizedBox(width: 6),
                          const Text(
                            'Stamp Controls',
                            style: TextStyle(
                              color: _kTextPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (_isMovingStamp) ...[
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() => _isMovingStamp = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: _kAccentPrimary.withOpacity(0.25),
                                  border: Border.all(color: _kAccentPrimary),
                                ),
                                child: const Text(
                                  'Done Moving',
                                  style: TextStyle(
                                    color: _kAccentPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
