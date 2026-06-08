class ParsedRosterEntry {
  const ParsedRosterEntry({
    required this.displayName,
    this.note = '',
  });

  final String displayName;
  final String note;

  bool get isValid => displayName.trim().isNotEmpty;

  ParsedRosterEntry copyWith({
    String? displayName,
    String? note,
  }) {
    return ParsedRosterEntry(
      displayName: displayName ?? this.displayName,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toJson() => {
        'displayName': displayName,
        'note': note,
      };

  static ParsedRosterEntry fromJson(Map<String, Object?> json) {
    return ParsedRosterEntry(
      displayName: json['displayName'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}
