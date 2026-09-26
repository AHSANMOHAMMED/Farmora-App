import 'dart:convert';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/error_reporter.dart';
import '../../../core/utils/app_errors.dart';

/// Builds an RFC 4180 CSV document from a header row and data rows.
String buildCsv(List<String> header, List<List<Object?>> rows) {
  String cell(Object? value) {
    final text = value == null
        ? ''
        : value is DateTime
            ? value.toIso8601String()
            : value.toString();
    final needsQuotes = text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r');
    final escaped = text.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  final buffer = StringBuffer()..writeln(header.map(cell).join(','));
  for (final row in rows) {
    buffer.writeln(row.map(cell).join(','));
  }
  return buffer.toString();
}

bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);

/// Saves [csv] as [fileName] through the platform save dialog. If saving is
/// not supported or fails, copies the CSV to the clipboard instead. Reports
/// the outcome in a SnackBar.
Future<void> exportCsv(
  BuildContext context, {
  required String fileName,
  required String csv,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final bytes = Uint8List.fromList(utf8.encode(csv));
  try {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save $fileName',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: bytes,
    );
    if (path == null) {
      // User cancelled the dialog (web downloads also return null).
      if (kIsWeb) {
        messenger.showSnackBar(
            SnackBar(content: Text('$fileName downloaded.')));
      }
      return;
    }
    // Desktop implementations only return the chosen path; write it here.
    if (_isDesktop) {
      await File(path).writeAsBytes(bytes, flush: true);
    }
    messenger.showSnackBar(SnackBar(content: Text('Saved $fileName')));
  } catch (e, st) {
    ErrorReporter.record(e, st, reason: 'Failed to save CSV $fileName');
    try {
      await Clipboard.setData(ClipboardData(text: csv));
      messenger.showSnackBar(const SnackBar(
          content: Text(
              'Saving files is not supported here. CSV copied to clipboard.')));
    } catch (clipErr) {
      messenger.showSnackBar(SnackBar(
          content: Text(userMessage(clipErr, action: 'export CSV'))));
    }
  }
}
