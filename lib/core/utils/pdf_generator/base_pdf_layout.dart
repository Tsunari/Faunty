import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

abstract class BasePdfLayout {
  Future<pw.ThemeData> getTheme() async {
  final font = await PdfGoogleFonts.notoSansRegular();
  final boldFont = await PdfGoogleFonts.notoSansBold();
  final italicFont = await PdfGoogleFonts.notoSansItalic();

    return pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
      italic: italicFont,
    );
  }

  pw.Widget buildHeader(pw.Context context, String title) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20.0),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }

  pw.Widget buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            DateFormat.yMMMd().format(DateTime.now()),
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> buildContent(pw.Context context, Map<String, List<Map<String, dynamic>>> data);
}
