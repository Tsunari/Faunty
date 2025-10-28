import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:faunty/tools/pdf_generator/base_pdf_layout.dart';
import 'package:faunty/tools/pdf_generator/pdf_generator.dart';
import 'package:faunty/tools/translation_helper.dart';

class PdfPreviewPage extends StatefulWidget {
  final String title;
  final Map<String, List<Map<String, dynamic>>> data;
  final BasePdfLayout? layout;

  const PdfPreviewPage({
    super.key,
    required this.title,
    required this.data,
    this.layout,
  });

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  bool _showFooter = false;

  @override
  Widget build(BuildContext context) {
    final previewTitle = translation(context: context, 'PDF Preview');
    final toggleLabel = translation(context: context, 'Show footer');
  final fileName = _buildFileName(widget.title);

    return Scaffold(
      appBar: AppBar(
        title: Text(previewTitle),
      ),
      body: PdfPreview(
        maxPageWidth: 800,
        allowPrinting: true,
        allowSharing: true,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName: fileName,
        canDebug: false,
        actions: [
          PdfPreviewAction(
            icon: Tooltip(
              message: toggleLabel,
              child: Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: _showFooter,
                  onChanged: (value) {
                    setState(() {
                      _showFooter = value;
                    });
                  },
                ),
              ),
            ),
            onPressed: (_, _, _) async {},
          ),
        ],
        build: (format) => PdfGenerator.generatePdfBytes(
          title: widget.title,
          data: widget.data,
          layout: widget.layout,
          pageFormat: format,
          showFooter: _showFooter,
        ),
      ),
    );
  }

  String _buildFileName(String rawTitle) {
    final normalized = rawTitle
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');

    final sanitized = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return sanitized.isEmpty ? 'document.pdf' : '$sanitized.pdf';
  }
}
