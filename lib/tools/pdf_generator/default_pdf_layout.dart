import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'base_pdf_layout.dart';

class DefaultPdfLayout extends BasePdfLayout {
  @override
  List<pw.Widget> buildContent(pw.Context context, Map<String, List<Map<String, dynamic>>> data) {
    return [
      ...data.entries.map((entry) {
        if (entry.value.isEmpty) {
          return pw.Container();
        }
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 20, bottom: 10),
              child: pw.Text(
                entry.key,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                  color: PdfColors.blueGrey800,
                ),
              ),
            ),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey600,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              data: <List<String>>[
                entry.value.first.keys.toList(),
                ...entry.value.map((row) => row.values.map((value) => value.toString()).toList()),
              ],
              border: pw.TableBorder.all(color: PdfColors.blueGrey100),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.blueGrey100,
                    width: .5,
                  ),
                ),
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
            ),
          ],
        );
      }).toList(),
    ];
  }
}
