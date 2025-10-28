import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'base_pdf_layout.dart';

class ProgramPdfLayout extends BasePdfLayout {
  @override
  List<pw.Widget> buildContent(
    pw.Context context,
    Map<String, List<Map<String, dynamic>>> data,
  ) {
    final widgets = <pw.Widget>[];
    final groups = <String, _ProgramGroup>{};
    final order = <String>[];

    final orderedEntries = data.entries.toList()
      ..sort((a, b) => _dayIndex(a.key).compareTo(_dayIndex(b.key)));

    for (final entry in orderedEntries) {
      final scheduleKey = _buildKey(entry.value);
      if (!groups.containsKey(scheduleKey)) {
        groups[scheduleKey] = _ProgramGroup([], entry.value);
        order.add(scheduleKey);
      }
      groups[scheduleKey]!.days.add(entry.key);
    }

    for (final key in order) {
      final group = groups[key]!;
      if (group.entries.isEmpty) {
        continue;
      }

      group.days.sort((a, b) => _dayIndex(a).compareTo(_dayIndex(b)));

      final title = group.days.length == 1
          ? group.days.first
          : group.days.join(', ');

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 20, bottom: 10),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 18,
              color: PdfColors.blueGrey800,
            ),
          ),
        ),
      );

      final headers = group.entries.first.keys.toList();
      final tableData = <List<String>>[
        headers,
        ...group.entries.map(
          (row) => headers
              .map((header) => row[header]?.toString() ?? '')
              .toList(),
        ),
      ];

      widgets.add(
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
          data: tableData,
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
      );
    }

    return widgets;
  }

  String _buildKey(List<Map<String, dynamic>> entries) {
    return entries
        .map(
          (row) => '${row['From'] ?? ''}|${row['To'] ?? ''}|${row['Event'] ?? ''}',
        )
        .join('||');
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

class _ProgramGroup {
  _ProgramGroup(this.days, this.entries);

  final List<String> days;
  final List<Map<String, dynamic>> entries;
}
