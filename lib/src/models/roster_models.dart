enum RosterType {
  temporary,
  longTerm;

  String get label => switch (this) {
        RosterType.temporary => '临时',
        RosterType.longTerm => '长期',
      };

  static RosterType fromName(String? name) {
    return RosterType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => RosterType.temporary,
    );
  }
}

const defaultStatusOptions = ['到了', '没到', '迟到', '请假'];

class Roster {
  const Roster({
    required this.id,
    required this.name,
    required this.type,
    required this.statusOptions,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final RosterType type;
  final List<String> statusOptions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Roster copyWith({
    String? name,
    RosterType? type,
    List<String>? statusOptions,
    DateTime? updatedAt,
  }) {
    return Roster(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      statusOptions: statusOptions ?? this.statusOptions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'statusOptions': statusOptions,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static Roster fromJson(Map<String, Object?> json) {
    return Roster(
      id: json['id'] as String,
      name: json['name'] as String? ?? '未命名花名册',
      type: RosterType.fromName(json['type'] as String?),
      statusOptions: (json['statusOptions'] as List<dynamic>?)
              ?.whereType<String>()
              .where((status) => status.trim().isNotEmpty)
              .toList() ??
          List<String>.from(defaultStatusOptions),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class RosterEntry {
  const RosterEntry({
    required this.id,
    required this.rosterId,
    required this.displayName,
    this.note = '',
    required this.sortOrder,
  });

  final String id;
  final String rosterId;
  final String displayName;
  final String note;
  final int sortOrder;

  RosterEntry copyWith({
    String? displayName,
    String? note,
    int? sortOrder,
  }) {
    return RosterEntry(
      id: id,
      rosterId: rosterId,
      displayName: displayName ?? this.displayName,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'rosterId': rosterId,
        'displayName': displayName,
        'note': note,
        'sortOrder': sortOrder,
      };

  static RosterEntry fromJson(Map<String, Object?> json) {
    return RosterEntry(
      id: json['id'] as String,
      rosterId: json['rosterId'] as String,
      displayName: json['displayName'] as String? ?? '',
      note: json['note'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class RosterSession {
  const RosterSession({
    required this.id,
    required this.rosterId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String rosterId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'rosterId': rosterId,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static RosterSession fromJson(Map<String, Object?> json) {
    return RosterSession(
      id: json['id'] as String,
      rosterId: json['rosterId'] as String,
      title: json['title'] as String? ?? '未命名记录',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class SessionResult {
  const SessionResult({
    required this.sessionId,
    required this.entryId,
    required this.statusLabel,
    required this.updatedAt,
  });

  final String sessionId;
  final String entryId;
  final String statusLabel;
  final DateTime updatedAt;

  SessionResult copyWith({
    String? statusLabel,
    DateTime? updatedAt,
  }) {
    return SessionResult(
      sessionId: sessionId,
      entryId: entryId,
      statusLabel: statusLabel ?? this.statusLabel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'sessionId': sessionId,
        'entryId': entryId,
        'statusLabel': statusLabel,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static SessionResult fromJson(Map<String, Object?> json) {
    return SessionResult(
      sessionId: json['sessionId'] as String,
      entryId: json['entryId'] as String,
      statusLabel: json['statusLabel'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
