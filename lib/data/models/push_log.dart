/// A single push-up log entry.
///
/// Represents one set/session of push-ups. Multiple logs can exist
/// for the same day. The daily aggregate is computed separately.
class PushLog {
  final String id;
  final String userId;
  final int amount;
  final String exerciseId;
  final DateTime loggedAt;
  final String localDate; // YYYY-MM-DD
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PushLog({
    required this.id,
    required this.userId,
    required this.amount,
    this.exerciseId = 'pushups',
    required this.loggedAt,
    required this.localDate,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PushLog.fromMap(Map<String, dynamic> map) {
    return PushLog(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as int?) ?? (map['count'] as int?) ?? 0,
      exerciseId: map['exerciseId'] as String? ?? 'pushups',
      loggedAt: _parseTimestamp(map['loggedAt']),
      localDate: map['localDate'] as String? ?? '',
      timezone: map['timezone'] as String? ?? 'UTC',
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'exerciseId': exerciseId,
      'loggedAt': loggedAt.toIso8601String(),
      'localDate': localDate,
      'timezone': timezone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
