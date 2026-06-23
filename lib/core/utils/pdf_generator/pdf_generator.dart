import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:faunty/core/utils/pdf_generator/base_pdf_layout.dart';
import 'package:faunty/core/utils/pdf_generator/default_pdf_layout.dart';

class PdfGenerator {
  static Future<void> generateAndPrintPdf({
    required String title,
    required Map<String, List<Map<String, dynamic>>> data,
    BasePdfLayout? layout,
    bool showFooter = true,
  }) async {
    final pdfLayout = layout ?? DefaultPdfLayout();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async =>
          _buildDocument(
            title: title,
            data: data,
            layout: pdfLayout,
            pageFormat: format,
            showFooter: showFooter,
          ).then((doc) => doc.save()),
    );
  }

  static Future<Uint8List> generatePdfBytes({
    required String title,
    required Map<String, List<Map<String, dynamic>>> data,
    BasePdfLayout? layout,
    PdfPageFormat? pageFormat,
    bool showFooter = true,
  }) async {
    final pdfLayout = layout ?? DefaultPdfLayout();
    final document = await _buildDocument(
      title: title,
      data: data,
      layout: pdfLayout,
      pageFormat: pageFormat ?? PdfPageFormat.a4,
      showFooter: showFooter,
    );

    return document.save();
  }

  static Future<pw.Document> _buildDocument({
    required String title,
    required Map<String, List<Map<String, dynamic>>> data,
    required BasePdfLayout layout,
    required PdfPageFormat pageFormat,
    required bool showFooter,
  }) async {
    final theme = await layout.getTheme();
    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => layout.buildHeader(context, title),
        footer: showFooter ? (context) => layout.buildFooter(context) : null,
        build: (context) => layout.buildContent(context, data),
      ),
    );

    return pdf;
  }
}