import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'base_pdf_layout.dart';

class StatisticsPdfLayout extends BasePdfLayout {
  final String itemName;
  final String dateStr;
  final String currentRating;
  final String totalRecords;
  final List<List<String>> historyData;
  final List<Map<String, String>> streaksData;

  StatisticsPdfLayout({
    required this.itemName,
    required this.dateStr,
    required this.currentRating,
    required this.totalRecords,
    required this.historyData,
    required this.streaksData,
  });

  @override
  List<pw.Widget> buildContent(pw.Context context, Map<String, List<Map<String, dynamic>>> data) {
    // We ignore 'data' here as we pass specific fields in constructor, 
    // or we could parse 'data' if we structured it that way.
    // For simplicity, we'll use the fields passed in constructor.
    
    return [
      pw.Text('Item: $itemName', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _pdfMetric('Current Rating', currentRating),
            _pdfMetric('Total Records', totalRecords),
          ],
        ),
      ),
      pw.SizedBox(height: 30),
      pw.Text('Recent History (Monthly)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      pw.TableHelper.fromTextArray(
        headers: ['Month', 'Present', 'On Leave'],
        data: historyData,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey600),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        border: pw.TableBorder.all(color: PdfColors.blueGrey100),
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      ),
      pw.SizedBox(height: 30),
      pw.Text('Best Streaks (Top 5)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      ...streaksData.map((r) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.SizedBox(width: 80, child: pw.Text(r['start']!)),
            pw.Text(' - '),
            pw.SizedBox(width: 80, child: pw.Text(r['end']!)),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(color: PdfColors.blue100, borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Text('${r['length']} days', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            ),
          ],
        ),
      )),
    ];
  }

  pw.Widget _pdfMetric(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      ],
    );
  }
}
