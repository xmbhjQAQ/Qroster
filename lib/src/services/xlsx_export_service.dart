import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/roster_models.dart';

class XlsxExportService {
  static const _excelMimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  Future<String> saveBytes({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final exportName = fileName.endsWith('.xlsx') ? fileName : '$fileName.xlsx';
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$exportName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: _excelMimeType)],
        fileNameOverrides: [exportName],
        subject: exportName,
        text: 'Q名册导出文件：$exportName',
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => '已打开系统分享/保存面板：$exportName',
      ShareResultStatus.dismissed => '已取消导出',
      ShareResultStatus.unavailable => '系统分享不可用，临时文件：${file.path}',
    };
  }

  Uint8List buildSingleSessionWorkbook({
    required Roster roster,
    required RosterSession session,
    required List<RosterEntry> entries,
    required List<SessionResult> results,
  }) {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', '记录');
    final sheet = workbook['记录'];
    final resultByEntryId = {
      for (final result in results) result.entryId: result.statusLabel,
    };
    final sessionTime = _formatDateTime(session.createdAt);

    sheet.appendRow([_text('花名册'), _text(roster.name)]);
    sheet.appendRow([_text('记录'), _text(session.title)]);
    sheet.appendRow([_text('导出时间'), _text(_formatDateTime(DateTime.now()))]);
    sheet.appendRow([]);
    sheet.appendRow([
      _text('序号'),
      _text('姓名'),
      _text('备注'),
      _text('状态'),
      _text('记录时间'),
    ]);
    for (final indexedEntry in entries.indexed) {
      final entry = indexedEntry.$2;
      sheet.appendRow([
        _text('${indexedEntry.$1 + 1}'),
        _text(entry.displayName),
        _text(entry.note),
        _text(_displayStatus(resultByEntryId[entry.id])),
        _text(sessionTime),
      ]);
    }
    _appendSummarySheet(
      workbook: workbook,
      roster: roster,
      entries: entries,
      sessions: [session],
      resultsBySessionId: {session.id: results},
    );

    return Uint8List.fromList(workbook.encode() ?? const []);
  }

  Uint8List buildLongTermHistoryWorkbook({
    required Roster roster,
    required List<RosterEntry> entries,
    required List<RosterSession> sessions,
    required List<SessionResult> results,
  }) {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', '全部记录');
    final sheet = workbook['全部记录'];
    final resultByKey = {
      for (final result in results)
        '${result.sessionId}:${result.entryId}': result.statusLabel,
    };

    sheet.appendRow([_text('花名册'), _text(roster.name)]);
    sheet.appendRow([_text('导出时间'), _text(_formatDateTime(DateTime.now()))]);
    sheet.appendRow([]);
    sheet.appendRow([
      _text('序号'),
      _text('姓名'),
      _text('备注'),
      ...sessions.map((session) => _text(session.title)),
    ]);

    for (final indexedEntry in entries.indexed) {
      final entry = indexedEntry.$2;
      sheet.appendRow([
        _text('${indexedEntry.$1 + 1}'),
        _text(entry.displayName),
        _text(entry.note),
        ...sessions.map(
          (session) =>
              _text(_displayStatus(resultByKey['${session.id}:${entry.id}'])),
        ),
      ]);
    }
    _appendSummarySheet(
      workbook: workbook,
      roster: roster,
      entries: entries,
      sessions: sessions,
      resultsBySessionId: {
        for (final session in sessions)
          session.id: results
              .where((result) => result.sessionId == session.id)
              .toList(),
      },
    );

    return Uint8List.fromList(workbook.encode() ?? const []);
  }

  String singleSessionFileName(Roster roster, RosterSession session) {
    return _safeFileName('qroster_${roster.name}_${session.title}');
  }

  String historyFileName(Roster roster) {
    return _safeFileName('qroster_${roster.name}_全部记录');
  }

  TextCellValue _text(String value) => TextCellValue(value);

  void _appendSummarySheet({
    required Excel workbook,
    required Roster roster,
    required List<RosterEntry> entries,
    required List<RosterSession> sessions,
    required Map<String, List<SessionResult>> resultsBySessionId,
  }) {
    final sheet = workbook['统计'];
    sheet.appendRow([_text('记录'), _text('状态'), _text('数量')]);
    for (final session in sessions) {
      final results = resultsBySessionId[session.id] ?? const [];
      final recordedEntryIds = results
          .where((result) => result.statusLabel.trim().isNotEmpty)
          .map((result) => result.entryId)
          .toSet();
      final statuses = [
        ...roster.statusOptions.where(
          (status) => status != unrecordedStatusLabel,
        ),
        unrecordedStatusLabel,
      ];
      for (final status in statuses) {
        final count = results
            .where((result) => result.statusLabel == status)
            .length;
        final displayCount = status == unrecordedStatusLabel
            ? entries.length - recordedEntryIds.length
            : count;
        sheet.appendRow([
          _text(session.title),
          _text(status),
          _text('$displayCount'),
        ]);
      }
    }
  }

  String _displayStatus(String? status) {
    final trimmed = status?.trim() ?? '';
    return trimmed.isEmpty ? unrecordedStatusLabel : trimmed;
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm').format(value);
  }

  String _safeFileName(String value) {
    return value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
