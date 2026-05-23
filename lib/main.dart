import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  runApp(const PdfStampMvpApp());
}

class PdfStampMvpApp extends StatelessWidget {
  const PdfStampMvpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Stamp MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const StampHomePage(),
    );
  }
}

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
  final TextEditingController _startPageCtl = TextEditingController(text: '1');
  final TextEditingController _endPageCtl = TextEditingController(text: '1');

  bool _isExporting = false;

  @override
  void dispose() {
    _pdfController?.dispose();
    _startPageCtl.dispose();
    _endPageCtl.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final sizeMb = await file.length() / (1024 * 1024);
    if (sizeMb > 50) {
      _showSnack('PDF is ${sizeMb.toStringAsFixed(1)}MB. Please keep under 50MB for MVP.');
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

  Future<void> _pickStampPng() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png'],
      withData: true,
    );
    if (result == null) return;

    final bytes = result.files.single.bytes ??
        await File(result.files.single.path!).readAsBytes();

    final cleaned = _makeWhiteTransparent(bytes);
    if (cleaned == null) {
      _showSnack('Could not process stamp PNG.');
      return;
    }

    setState(() {
      _stampFile = result.files.single.path == null ? null : File(result.files.single.path!);
      _cleanedStampPng = cleaned;
    });
  }

  Uint8List? _makeWhiteTransparent(Uint8List inputPng) {
    final source = img.decodeImage(inputPng);
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
          final faded = (a * (1.0 - t * 0.85)).round();
          outAlpha = faded;
        }

        out.setPixelRgba(x, y, r, g, b, outAlpha);
      }
    }

    final encoded = img.encodePng(out);
    return Uint8List.fromList(encoded);
  }

  Future<void> _exportStampedPdf() async {
    if (_pdfFile == null || _cleanedStampPng == null) {
      _showSnack('Pick both a PDF and a stamp first.');
      return;
    }

    setState(() => _isExporting = true);
    try {
      final pdfBytes = await _pdfFile!.readAsBytes();
      final document = PdfDocument(inputBytes: pdfBytes);

      final pageIndexes = _buildPageIndexes(document.pages.count);
      if (pageIndexes.isEmpty) {
        document.dispose();
        _showSnack('No valid pages selected.');
        return;
      }

      for (final idx in pageIndexes) {
        final page = document.pages[idx];
        final pageSize = page.size;

        final previewW = MediaQuery.of(context).size.width - 32;
        final previewH = (MediaQuery.of(context).size.height * 0.55).clamp(1, 2000).toDouble();

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

        page.graphics.drawImage(
          PdfBitmap(_cleanedStampPng!),
          Rect.fromLTWH(0, 0, w, h),
        );

        page.graphics.restore(state);
      }

      final outputBytes = Uint8List.fromList(await document.save());
      document.dispose();

      final dir = _pdfFile!.parent;
      final base = p.basenameWithoutExtension(_pdfFile!.path);
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
    if (_applyAllPages) {
      return List<int>.generate(totalPages, (i) => i);
    }

    final start = int.tryParse(_startPageCtl.text.trim()) ?? _pageNumber;
    final end = int.tryParse(_endPageCtl.text.trim()) ?? _pageNumber;

    final s = start.clamp(1, totalPages);
    final e = end.clamp(1, totalPages);
    final from = s <= e ? s : e;
    final to = s <= e ? e : s;

    return [for (var p = from; p <= to; p++) p - 1];
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final canPlaceStamp = _pdfFile != null && _cleanedStampPng != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Offline PDF Stamp MVP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _pickPdf,
                    child: const Text('Pick PDF'),
                  ),
                  FilledButton.tonal(
                    onPressed: _pickStampPng,
                    child: const Text('Pick Stamp PNG'),
                  ),
                  FilledButton(
                    onPressed: _isExporting ? null : _exportStampedPdf,
                    child: Text(_isExporting ? 'Exporting...' : 'Export Stamped PDF'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('PDF: ${_pdfFile?.path ?? '-'}'),
              Text('Stamp: ${_stampFile?.path ?? 'Loaded from memory'}'),
              const SizedBox(height: 14),
              if (_pdfController != null)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: Stack(
                    children: [
                      PdfViewPinch(
                        controller: _pdfController!,
                        onPageChanged: (page) {
                          setState(() {
                            _pageNumber = page;
                          });
                        },
                        onDocumentLoaded: (doc) {
                          setState(() {
                            _pageCount = doc.pagesCount;
                            _startPageCtl.text = '$_pageNumber';
                            _endPageCtl.text = '$_pageNumber';
                          });
                        },
                      ),
                      if (_cleanedStampPng != null)
                        Positioned(
                          left: _stampX,
                          top: _stampY,
                          child: GestureDetector(
                            onPanUpdate: (d) {
                              setState(() {
                                _stampX = (_stampX + d.delta.dx).clamp(0.0, 10000.0);
                                _stampY = (_stampY + d.delta.dy).clamp(0.0, 10000.0);
                              });
                            },
                            child: Transform.rotate(
                              angle: _rotationDeg * 3.1415926535 / 180.0,
                              child: Image.memory(
                                _cleanedStampPng!,
                                width: _stampW,
                                height: _stampH,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                const SizedBox(
                  height: 200,
                  child: Center(child: Text('Pick a PDF to preview and place stamp.')),
                ),
              const SizedBox(height: 12),
              Text('Page $_pageNumber of $_pageCount'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    child: SwitchListTile.adaptive(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Apply all'),
                      value: _applyAllPages,
                      onChanged: canPlaceStamp
                          ? (v) => setState(() {
                                _applyAllPages = v;
                              })
                          : null,
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _startPageCtl,
                      enabled: !_applyAllPages,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Start'),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _endPageCtl,
                      enabled: !_applyAllPages,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'End'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Stamp controls'),
              Slider(
                value: _stampW,
                min: 40,
                max: 380,
                label: 'Width',
                onChanged: canPlaceStamp ? (v) => setState(() => _stampW = v) : null,
              ),
              Slider(
                value: _stampH,
                min: 25,
                max: 260,
                label: 'Height',
                onChanged: canPlaceStamp ? (v) => setState(() => _stampH = v) : null,
              ),
              Slider(
                value: _rotationDeg,
                min: -180,
                max: 180,
                label: 'Rotation',
                onChanged: canPlaceStamp ? (v) => setState(() => _rotationDeg = v) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
