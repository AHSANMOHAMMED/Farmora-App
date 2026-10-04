import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

String profileExportCsv(Map<String, dynamic> data) {
  final rows = <List<Object?>>[
    ['Section', 'Key', 'Value'],
  ];

  void addValue(String section, String key, Object? value) {
    if (value is Map) {
      for (final entry in value.entries) {
        addValue('$section.$key', entry.key.toString(), entry.value);
      }
      return;
    }
    if (value is List) {
      for (var index = 0; index < value.length; index++) {
        addValue('$section.$key', index.toString(), value[index]);
      }
      return;
    }
    rows.add([section, key, value]);
  }

  for (final entry in data.entries) {
    addValue('profile_export', entry.key, entry.value);
  }

  String cell(Object? value) {
    final text = value is String ? value : jsonEncode(value);
    final escaped = text.replaceAll('"', '""');
    final quoted = text.contains(',') ||
        text.contains('"') ||
        text.contains('\r') ||
        text.contains('\n');
    return quoted ? '"$escaped"' : escaped;
  }

  return rows.map((row) => row.map(cell).join(',')).join('\r\n');
}

Future<Uint8List> profileExportPdf(Map<String, dynamic> data) async {
  final doc = pw.Document(title: 'Farmora profile export');
  final profile = data['profile'];
  final entries = data.entries.toList();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Text(
          'Farmora data export',
          style:
              const pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Generated: ${data['exportedAt'] ?? '-'}'),
        if (profile is Map) ...[
          pw.SizedBox(height: 20),
          pw.Text('Profile',
              style: const pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.TableHelper.fromTextArray(
            headers: const ['Field', 'Value'],
            data: profile.entries
                .map((entry) => [entry.key.toString(), _pdfValue(entry.value)])
                .toList(),
          ),
        ],
        pw.SizedBox(height: 20),
        pw.Text('Included records',
            style: const pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(
          headers: const ['Section', 'Records'],
          data: entries
              .where((entry) => entry.key != 'profile')
              .map((entry) =>
                  [entry.key, entry.value is List ? entry.value.length : 1])
              .toList(),
        ),
      ],
    ),
  );
  return doc.save();
}

String _pdfValue(Object? value) {
  if (value is Map || value is List) return jsonEncode(value);
  return value?.toString() ?? '';
}
