import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../models/app_data.dart';
import '../models/app_settings.dart';
import '../models/parsed_roster_entry.dart';
import '../models/roster_models.dart';
import '../services/import_service.dart';
import '../services/llm_import_service.dart';
import '../services/xlsx_export_service.dart';
import '../storage/qroster_store.dart';

class QrosterController extends ChangeNotifier {
  QrosterController({
    required this.store,
    ImportService? importService,
    LlmImportService? llmImportService,
    XlsxExportService? xlsxExportService,
  }) : _importService = importService ?? ImportService(),
       _llmImportService = llmImportService ?? LlmImportService(),
       _xlsxExportService = xlsxExportService ?? XlsxExportService();

  final QrosterStore store;
  final ImportService _importService;
  final LlmImportService _llmImportService;
  final XlsxExportService _xlsxExportService;
  final Uuid _uuid = const Uuid();

  AppData _data = AppData.empty();
  bool _isLoaded = false;

  AppSettings get settings => _data.settings;
  List<Roster> get rosters => List.unmodifiable(_data.rosters);
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _data = await store.load();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> completeOnboarding({required bool completed}) {
    return updateSettings(settings.copyWith(onboardingCompleted: completed));
  }

  Future<void> updateSettings(AppSettings settings) async {
    _data = _data.copyWith(settings: settings);
    await _persist();
  }

  List<RosterEntry> entriesFor(String rosterId) {
    final entries =
        _data.entries.where((entry) => entry.rosterId == rosterId).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return entries;
  }

  List<RosterSession> sessionsFor(String rosterId) {
    final sessions =
        _data.sessions.where((session) => session.rosterId == rosterId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  List<SessionResult> resultsFor(String sessionId) {
    return _data.results
        .where((result) => result.sessionId == sessionId)
        .toList();
  }

  int recordedCountFor({required String rosterId, required String sessionId}) {
    final entryIds = entriesFor(rosterId).map((entry) => entry.id).toSet();
    return _data.results
        .where(
          (result) =>
              result.sessionId == sessionId &&
              entryIds.contains(result.entryId) &&
              result.statusLabel.trim().isNotEmpty,
        )
        .length;
  }

  int unrecordedCountFor({
    required String rosterId,
    required String sessionId,
  }) {
    return entriesFor(rosterId).length -
        recordedCountFor(rosterId: rosterId, sessionId: sessionId);
  }

  int? firstUnrecordedIndex({
    required String rosterId,
    required String sessionId,
  }) {
    return nextUnrecordedIndex(
      rosterId: rosterId,
      sessionId: sessionId,
      startIndex: -1,
    );
  }

  int? nextUnrecordedIndex({
    required String rosterId,
    required String sessionId,
    required int startIndex,
  }) {
    final entries = entriesFor(rosterId);
    if (entries.isEmpty) {
      return null;
    }
    final normalizedStart = startIndex.clamp(-1, entries.length - 1).toInt();
    for (var index = normalizedStart + 1; index < entries.length; index += 1) {
      if (statusFor(sessionId: sessionId, entryId: entries[index].id).isEmpty) {
        return index;
      }
    }
    for (var index = 0; index <= normalizedStart; index += 1) {
      if (statusFor(sessionId: sessionId, entryId: entries[index].id).isEmpty) {
        return index;
      }
    }
    return null;
  }

  String latestRecordLabel(String rosterId) {
    final sessions = sessionsFor(rosterId);
    if (sessions.isEmpty) {
      return '尚未记录';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(sessions.first.createdAt);
  }

  int sessionCountFor(String rosterId) {
    return _data.sessions
        .where((session) => session.rosterId == rosterId)
        .length;
  }

  List<ParsedRosterEntry> parseText(String text) {
    return _importService.parsePlainText(text);
  }

  List<ParsedRosterEntry> parseSpreadsheet(Uint8List bytes) {
    return _importService.parseSpreadsheetBytes(bytes);
  }

  String spreadsheetTextForLlm(Uint8List bytes) {
    return _importService.spreadsheetBytesToText(bytes);
  }

  Future<List<ParsedRosterEntry>> parseWithLlm(String sourceText) {
    return _llmImportService.parseRoster(
      settings: settings,
      sourceText: sourceText,
    );
  }

  Future<Roster> createRoster({
    required String name,
    RosterType type = RosterType.longTerm,
    required List<String> statusOptions,
    required List<ParsedRosterEntry> parsedEntries,
  }) async {
    final now = DateTime.now();
    final roster = Roster(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? '未命名花名册' : name.trim(),
      type: type,
      statusOptions: _normalizeStatuses(statusOptions),
      createdAt: now,
      updatedAt: now,
    );
    final entries = parsedEntries
        .where((entry) => entry.isValid)
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => RosterEntry(
            id: _uuid.v4(),
            rosterId: roster.id,
            displayName: entry.value.displayName.trim(),
            note: entry.value.note.trim(),
            sortOrder: entry.key,
          ),
        )
        .toList();

    _data = _data.copyWith(
      rosters: [..._data.rosters, roster],
      entries: [..._data.entries, ...entries],
    );
    await _persist();
    return roster;
  }

  Future<void> updateRoster({
    required Roster roster,
    String? name,
    RosterType? type,
    List<String>? statusOptions,
  }) async {
    final updated = roster.copyWith(
      name: name,
      type: type,
      statusOptions: statusOptions == null
          ? null
          : _normalizeStatuses(statusOptions),
      updatedAt: DateTime.now(),
    );
    _data = _data.copyWith(
      rosters: _data.rosters
          .map((item) => item.id == roster.id ? updated : item)
          .toList(),
    );
    await _persist();
  }

  Future<void> updateEntry(RosterEntry entry) async {
    _data = _data.copyWith(
      entries: _data.entries
          .map((item) => item.id == entry.id ? entry : item)
          .toList(),
    );
    await _persist();
  }

  Future<void> pinRoster(String rosterId) async {
    final index = _data.rosters.indexWhere((roster) => roster.id == rosterId);
    if (index <= 0) {
      return;
    }
    final nextRosters = [..._data.rosters];
    final roster = nextRosters.removeAt(index);
    nextRosters.insert(0, roster.copyWith(updatedAt: DateTime.now()));
    _data = _data.copyWith(rosters: nextRosters);
    await _persist();
  }

  Future<void> deleteRoster(String rosterId) async {
    final sessionIds = _data.sessions
        .where((session) => session.rosterId == rosterId)
        .map((session) => session.id)
        .toSet();
    _data = _data.copyWith(
      rosters: _data.rosters.where((roster) => roster.id != rosterId).toList(),
      entries: _data.entries
          .where((entry) => entry.rosterId != rosterId)
          .toList(),
      sessions: _data.sessions
          .where((session) => session.rosterId != rosterId)
          .toList(),
      results: _data.results
          .where((result) => !sessionIds.contains(result.sessionId))
          .toList(),
    );
    await _persist();
  }

  Future<void> deleteSession(String sessionId) async {
    _data = _data.copyWith(
      sessions: _data.sessions
          .where((session) => session.id != sessionId)
          .toList(),
      results: _data.results
          .where((result) => result.sessionId != sessionId)
          .toList(),
    );
    await _persist();
  }

  Future<void> renameSession({
    required String sessionId,
    required String title,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('记录名称不能为空');
    }
    _data = _data.copyWith(
      sessions: _data.sessions
          .map(
            (session) => session.id == sessionId
                ? session.copyWith(title: trimmed, updatedAt: DateTime.now())
                : session,
          )
          .toList(),
    );
    await _persist();
  }

  Future<RosterSession> createSession(
    Roster roster, {
    DateTime? recordedAt,
    String? title,
  }) async {
    final now = recordedAt ?? DateTime.now();
    final defaultTitle = DateFormat('yyyy-MM-dd HH:mm').format(now);
    final sessionTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : defaultTitle;
    final session = RosterSession(
      id: _uuid.v4(),
      rosterId: roster.id,
      title: sessionTitle,
      createdAt: now,
      updatedAt: now,
    );
    _data = _data.copyWith(sessions: [..._data.sessions, session]);
    await _persist();
    return session;
  }

  Future<void> setResult({
    required String sessionId,
    required String entryId,
    required String statusLabel,
  }) async {
    final now = DateTime.now();
    final existingIndex = _data.results.indexWhere(
      (result) => result.sessionId == sessionId && result.entryId == entryId,
    );
    final nextResults = [..._data.results];
    if (existingIndex >= 0) {
      nextResults[existingIndex] = nextResults[existingIndex].copyWith(
        statusLabel: statusLabel,
        updatedAt: now,
      );
    } else {
      nextResults.add(
        SessionResult(
          sessionId: sessionId,
          entryId: entryId,
          statusLabel: statusLabel,
          updatedAt: now,
        ),
      );
    }
    _data = _data.copyWith(results: nextResults);
    await _persist();
  }

  String statusFor({required String sessionId, required String entryId}) {
    return _data.results
            .where(
              (result) =>
                  result.sessionId == sessionId && result.entryId == entryId,
            )
            .firstOrNull
            ?.statusLabel ??
        '';
  }

  Future<String> exportSingleSession({
    required Roster roster,
    required RosterSession session,
  }) {
    final entries = entriesFor(roster.id);
    final results = resultsFor(session.id);
    final bytes = _xlsxExportService.buildSingleSessionWorkbook(
      roster: roster,
      session: session,
      entries: entries,
      results: results,
    );
    return _xlsxExportService.saveBytes(
      fileName: _xlsxExportService.singleSessionFileName(roster, session),
      bytes: bytes,
    );
  }

  Future<String> exportHistory(Roster roster) {
    final sessions = sessionsFor(roster.id).reversed.toList();
    final sessionIds = sessions.map((session) => session.id).toSet();
    final results = _data.results
        .where((result) => sessionIds.contains(result.sessionId))
        .toList();
    final bytes = _xlsxExportService.buildLongTermHistoryWorkbook(
      roster: roster,
      entries: entriesFor(roster.id),
      sessions: sessions,
      results: results,
    );
    return _xlsxExportService.saveBytes(
      fileName: _xlsxExportService.historyFileName(roster),
      bytes: bytes,
    );
  }

  Future<void> _persist() async {
    await store.save(_data);
    notifyListeners();
  }

  List<String> _normalizeStatuses(List<String> statuses) {
    final cleaned = statuses
        .map((status) => status.trim())
        .where((status) => status.isNotEmpty)
        .toSet()
        .toList();
    return cleaned.isEmpty ? List<String>.from(defaultStatusOptions) : cleaned;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
