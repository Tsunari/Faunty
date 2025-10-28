import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'base_pdf_layout.dart';

class CateringPdfLayout extends BasePdfLayout {
  @override
  List<pw.Widget> buildContent(pw.Context context, Map<String, List<Map<String, dynamic>>> data) {
    final widgets = <pw.Widget>[];
    final uniformBuffer = <MapEntry<String, List<Map<String, dynamic>>>>[];

    void flushUniformBuffer() {
      if (uniformBuffer.isEmpty) return;

      final tableData = <List<String>>[
        ['Day', 'Assignees'],
        ...uniformBuffer.map((entry) {
          final assignees = entry.value.first['Assignees']?.toString() ?? '';
          return [entry.key, assignees];
        }),
      ];

      widgets.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(top: widgets.isEmpty ? 0 : 20),
          child: pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey600,
            ),
            cellAlignment: pw.Alignment.center,
            headerAlignments: const {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
            },
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            data: tableData,
            border: pw.TableBorder.all(color: PdfColors.blueGrey100),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey50,
            ),
          ),
        ),
      );

      uniformBuffer.clear();
    }

    final orderedEntries = data.entries.toList()
      ..sort((a, b) => _dayIndex(a.key).compareTo(_dayIndex(b.key)));

    for (final entry in orderedEntries) {
      if (entry.value.isEmpty) {
        continue;
      }

      final firstRow = entry.value.first;
      final isUniformDay = firstRow.containsKey('Assignees') && !firstRow.containsKey('Meal');

      if (isUniformDay) {
        uniformBuffer.add(entry);
        continue;
      }

      // Non-uniform day: flush any buffered uniform days first
      flushUniformBuffer();

      widgets.add(
        pw.Column(
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
            pw.TableHelper.fromTextArray(
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
                ...entry.value
                    .map((row) => row.values.map((value) => value.toString()).toList()),
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
        ),
      );
    }

    // Flush any remaining uniform days after loop
    flushUniformBuffer();

    return widgets;
  }

  static const List<String> _weekOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  int _dayIndex(String day) {
    final idx = _weekOrder.indexOf(day);
    return idx == -1 ? _weekOrder.length : idx;
  }
}
