/// Immutable user model for RepCommit.
class UserModel {
  final String uid;
  final String username;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String timezone;
  final int weeklyTarget;
  final int dailyTarget;
  final int currentStreak;
  final int bestStreak;
  final int totalPushUps;
  final int activeDays;
  final double consistencyScore;
  final bool onboardingComplete;
  final Map<String, dynamic> notificationPreferences;

  const UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.timezone = 'UTC',
    this.weeklyTarget = 420,
    this.dailyTarget = 60,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalPushUps = 0,
    this.activeDays = 0,
    this.consistencyScore = 0.0,
    this.onboardingComplete = false,
    this.notificationPreferences = const {},
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      username: map['username'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      timezone: map['timezone'] as String? ?? 'UTC',
      weeklyTarget: map['weeklyTarget'] as int? ?? 420,
      dailyTarget: map['dailyTarget'] as int? ?? 60,
      currentStreak: map['currentStreak'] as int? ?? 0,
      bestStreak: map['bestStreak'] as int? ?? 0,
      totalPushUps: map['totalPushUps'] as int? ?? 0,
      activeDays: map['activeDays'] as int? ?? 0,
      consistencyScore: (map['consistencyScore'] as num?)?.toDouble() ?? 0.0,
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      notificationPreferences:
          Map<String, dynamic>.from(map['notificationPreferences'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'timezone': timezone,
      'weeklyTarget': weeklyTarget,
      'dailyTarget': dailyTarget,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'totalPushUps': totalPushUps,
      'activeDays': activeDays,
      'consistencyScore': consistencyScore,
      'onboardingComplete': onboardingComplete,
      'notificationPreferences': notificationPreferences,
    };
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? timezone,
    int? weeklyTarget,
    int? dailyTarget,
    int? currentStreak,
    int? bestStreak,
    int? totalPushUps,
    int? activeDays,
    double? consistencyScore,
    bool? onboardingComplete,
    Map<String, dynamic>? notificationPreferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timezone: timezone ?? this.timezone,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      totalPushUps: totalPushUps ?? this.totalPushUps,
      activeDays: activeDays ?? this.activeDays,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
