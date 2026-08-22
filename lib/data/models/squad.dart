/// Squad model.
class Squad {
  final String id;
  final String name;
  final String ownerId;
  final String goal;
  final int target;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // active, archived
  final int memberCount;
  final DateTime createdAt;

  const Squad({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.goal,
    required this.target,
    required this.startDate,
    this.endDate,
    this.status = 'active',
    this.memberCount = 1,
    required this.createdAt,
  });

  factory Squad.fromMap(Map<String, dynamic> map) {
    return Squad(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      goal: map['goal'] as String? ?? '',
      target: map['target'] as int? ?? 500,
      startDate: _parseTimestamp(map['startDate']),
      endDate: _tryParse(map['endDate']),
      status: map['status'] as String? ?? 'active',
      memberCount: map['memberCount'] as int? ?? 1,
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'goal': goal,
      'target': target,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
      'memberCount': memberCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static DateTime? _tryParse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Squad challenge model.
class SquadChallenge {
  final String id;
  final String squadId;
  final String name;
  final int target;
  final int progress;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;
  final String status; // active, completed, expired

  const SquadChallenge({
    required this.id,
    required this.squadId,
    required this.name,
    required this.target,
    this.progress = 0,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    this.status = 'active',
  });

  factory SquadChallenge.fromMap(Map<String, dynamic> map) {
    return SquadChallenge(
      id: map['id'] as String? ?? '',
      squadId: map['squadId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      target: map['target'] as int? ?? 1000,
      progress: map['progress'] as int? ?? 0,
      startDate: Squad._parseTimestamp(map['startDate']),
      endDate: Squad._parseTimestamp(map['endDate']),
      createdBy: map['createdBy'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'squadId': squadId,
      'name': name,
      'target': target,
      'progress': progress,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdBy': createdBy,
      'status': status,
    };
  }

  double get progressPercent => target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  int get daysRemaining {
    final remaining = endDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }
}
