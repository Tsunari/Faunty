import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:faunty/core/widgets/custom_snackbar.dart';
import 'package:faunty/core/utils/pdf_generator/base_pdf_layout.dart';
import 'package:faunty/core/utils/pdf_generator/pdf_generator.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: previewTitle, useModern: false,
      ),
      body: PdfPreview(
        maxPageWidth: 800,
        allowPrinting: true,
        allowSharing: true,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName: fileName,
        canDebug: false,
        enableScrollToPage: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        previewPageMargin: const EdgeInsets.symmetric(vertical: 12),
        scrollViewDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
        ),
        pdfPreviewPageDecoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        loadingWidget: const Center(child: CircularProgressIndicator()),
        shareActionExtraSubject: widget.title,
        shareActionExtraBody: translation(
          context: context,
          'Generated via Faunty PDF export.',
        ),
        onPrinted: (ctx) {
          showCustomSnackBar(
            ctx,
            translation(context: ctx, 'PDF sent to printer.'),
          );
        },
        onShared: (ctx) {
          showCustomSnackBar(
            ctx,
            translation(context: ctx, 'PDF shared successfully.'),
          );
        },
        onPrintError: (ctx, error) {
          showCustomSnackBar(
            ctx,
            translation(context: ctx, 'Printing failed.'),
            backgroundColor: theme.colorScheme.error,
          );
        },
        onError: (ctx, error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    translation(context: ctx, 'Failed to render PDF preview.'),
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        },
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