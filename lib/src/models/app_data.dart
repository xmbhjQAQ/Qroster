import 'app_settings.dart';
import 'roster_models.dart';

class AppData {
  const AppData({
    required this.settings,
    required this.rosters,
    required this.entries,
    required this.sessions,
    required this.results,
  });

  factory AppData.empty() {
    return const AppData(
      settings: AppSettings(),
      rosters: [],
      entries: [],
      sessions: [],
      results: [],
    );
  }

  final AppSettings settings;
  final List<Roster> rosters;
  final List<RosterEntry> entries;
  final List<RosterSession> sessions;
  final List<SessionResult> results;

  AppData copyWith({
    AppSettings? settings,
    List<Roster>? rosters,
    List<RosterEntry>? entries,
    List<RosterSession>? sessions,
    List<SessionResult>? results,
  }) {
    return AppData(
      settings: settings ?? this.settings,
      rosters: rosters ?? this.rosters,
      entries: entries ?? this.entries,
      sessions: sessions ?? this.sessions,
      results: results ?? this.results,
    );
  }

  Map<String, Object?> toJson() => {
        'settings': settings.toJson(),
        'rosters': rosters.map((roster) => roster.toJson()).toList(),
        'entries': entries.map((entry) => entry.toJson()).toList(),
        'sessions': sessions.map((session) => session.toJson()).toList(),
        'results': results.map((result) => result.toJson()).toList(),
      };

  static AppData fromJson(Map<String, Object?> json) {
    return AppData(
      settings: AppSettings.fromJson(
        (json['settings'] as Map<dynamic, dynamic>?)?.cast<String, Object?>() ??
            const {},
      ),
      rosters: (json['rosters'] as List<dynamic>?)
              ?.whereType<Map<dynamic, dynamic>>()
              .map((item) => Roster.fromJson(item.cast<String, Object?>()))
              .toList() ??
          const [],
      entries: (json['entries'] as List<dynamic>?)
              ?.whereType<Map<dynamic, dynamic>>()
              .map((item) => RosterEntry.fromJson(item.cast<String, Object?>()))
              .toList() ??
          const [],
      sessions: (json['sessions'] as List<dynamic>?)
              ?.whereType<Map<dynamic, dynamic>>()
              .map(
                (item) => RosterSession.fromJson(item.cast<String, Object?>()),
              )
              .toList() ??
          const [],
      results: (json['results'] as List<dynamic>?)
              ?.whereType<Map<dynamic, dynamic>>()
              .map(
                (item) => SessionResult.fromJson(item.cast<String, Object?>()),
              )
              .toList() ??
          const [],
    );
  }
}
