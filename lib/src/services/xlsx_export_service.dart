import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

import '../models/roster_models.dart';

class XlsxExportService {
  Future<String> saveBytes({
    required String fileName,
    required Uint8List bytes,
  }) {
    return FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  Uint8List buildSingleSessionWorkbook({
    required Roster roster,
    required RosterSession session,
    required List<RosterEntry> entries,
    required List<SessionResult> results,
  }) {
    final workbook = Excel.createExcel();
    final sheet = workbook['Sheet1'];
    final resultByEntryId = {
      for (final result in results) result.entryId: result.statusLabel,
    };

    sheet.appendRow([
      _text('花名册'),
      _text(roster.name),
    ]);
    sheet.appendRow([
      _text('记录'),
      _text(session.title),
    ]);
    sheet.appendRow([
      _text('导出时间'),
      _text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      _text('姓名'),
      _text('备注'),
      _text('状态'),
    ]);
    for (final entry in entries) {
      sheet.appendRow([
        _text(entry.displayName),
        _text(entry.note),
        _text(resultByEntryId[entry.id] ?? ''),
      ]);
    }

    return Uint8List.fromList(workbook.encode() ?? const []);
  }

  Uint8List buildLongTermHistoryWorkbook({
    required Roster roster,
    required List<RosterEntry> entries,
    required List<RosterSession> sessions,
    required List<SessionResult> results,
  }) {
    final workbook = Excel.createExcel();
    final sheet = workbook['Sheet1'];
    final resultByKey = {
      for (final result in results)
        '${result.sessionId}:${result.entryId}': result.statusLabel,
    };

    sheet.appendRow([
      _text('花名册'),
      _text(roster.name),
    ]);
    sheet.appendRow([
      _text('类型'),
      _text(roster.type.label),
    ]);
    sheet.appendRow([
      _text('导出时间'),
      _text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      _text('姓名'),
      _text('备注'),
      ...sessions.map((session) => _text(session.title)),
    ]);

    for (final entry in entries) {
      sheet.appendRow([
        _text(entry.displayName),
        _text(entry.note),
        ...sessions.map(
          (session) => _text(resultByKey['${session.id}:${entry.id}'] ?? ''),
        ),
      ]);
    }

    return Uint8List.fromList(workbook.encode() ?? const []);
  }

  String singleSessionFileName(Roster roster, RosterSession session) {
    return _safeFileName('qroster_${roster.name}_${session.title}');
  }

  String historyFileName(Roster roster) {
    return _safeFileName('qroster_${roster.name}_全部记录');
  }

  TextCellValue _text(String value) => TextCellValue(value);

  String _safeFileName(String value) {
    return value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
