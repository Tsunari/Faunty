import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'base_pdf_layout.dart';
import 'default_pdf_layout.dart';

class PdfGenerator {
  static Future<void> generateAndPrintPdf({
    required String title,
    required Map<String, List<Map<String, dynamic>>> data,
    BasePdfLayout? layout,
  }) async {
    final pdfLayout = layout ?? DefaultPdfLayout();
    final theme = await pdfLayout.getTheme();
    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pdfLayout.buildHeader(context, title),
        footer: (context) => pdfLayout.buildFooter(context),
        build: (context) => pdfLayout.buildContent(context, data),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
