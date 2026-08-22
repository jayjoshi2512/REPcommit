/// Daily aggregate statistics for push-ups.
///
/// Computed from individual [PushLog] entries. One document per user per day.
class DailyStats {
  final String date; // YYYY-MM-DD
  final int totalPushUps;
  final int sessionCount;
  final DateTime? firstLoggedAt;
  final DateTime? lastLoggedAt;
  final int target;
  final bool targetReached;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyStats({
    required this.date,
    this.totalPushUps = 0,
    this.sessionCount = 0,
    this.firstLoggedAt,
    this.lastLoggedAt,
    this.target = 60,
    this.targetReached = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyStats.empty(String date, {int target = 60}) {
    final now = DateTime.now();
    return DailyStats(
      date: date,
      target: target,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      date: map['date'] as String? ?? '',
      totalPushUps: map['totalPushUps'] as int? ?? 0,
      sessionCount: map['sessionCount'] as int? ?? 0,
      firstLoggedAt: _tryParse(map['firstLoggedAt']),
      lastLoggedAt: _tryParse(map['lastLoggedAt']),
      target: map['target'] as int? ?? 60,
      targetReached: map['targetReached'] as bool? ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalPushUps': totalPushUps,
      'sessionCount': sessionCount,
      'firstLoggedAt': firstLoggedAt?.toIso8601String(),
      'lastLoggedAt': lastLoggedAt?.toIso8601String(),
      'target': target,
      'targetReached': targetReached,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  DailyStats copyWith({
    String? date,
    int? totalPushUps,
    int? sessionCount,
    DateTime? firstLoggedAt,
    DateTime? lastLoggedAt,
    int? target,
    bool? targetReached,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyStats(
      date: date ?? this.date,
      totalPushUps: totalPushUps ?? this.totalPushUps,
      sessionCount: sessionCount ?? this.sessionCount,
      firstLoggedAt: firstLoggedAt ?? this.firstLoggedAt,
      lastLoggedAt: lastLoggedAt ?? this.lastLoggedAt,
      target: target ?? this.target,
      targetReached: targetReached ?? this.targetReached,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _tryParse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
