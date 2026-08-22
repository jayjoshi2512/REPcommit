/// Achievement definition and user achievement unlock models.
///
/// Definition of an achievement — the template.
class AchievementDef {
  final String id;
  final String title;
  final String category;
  final String description;
  final String shortLabel;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    required this.shortLabel,
  });

  /// All achievement definitions for RepCommit.
  static const List<AchievementDef> all = [
    // Personal
    AchievementDef(id: 'first_push', title: 'First push', category: 'personal', shortLabel: '01'),
    AchievementDef(id: 'century_club', title: 'Century club', category: 'personal', shortLabel: '100'),
    AchievementDef(id: 'day_250', title: '250 in one day', category: 'personal', shortLabel: '250'),
    AchievementDef(id: 'week_500', title: '500 week', category: 'personal', shortLabel: '500'),
    AchievementDef(id: 'week_1000', title: '1000 week', category: 'personal', shortLabel: '1k'),
    AchievementDef(id: 'total_5000', title: '5000 total', category: 'personal', shortLabel: '5k'),
    AchievementDef(id: 'total_10000', title: '10k total', category: 'personal', shortLabel: '10k'),
    AchievementDef(id: 'dawn_set', title: 'Dawn set', category: 'personal', shortLabel: '6AM'),
    AchievementDef(id: 'night_shift', title: 'Night shift', category: 'personal', shortLabel: 'PM'),

    // Consistency
    AchievementDef(id: 'streak_7', title: '7-day line', category: 'consistency', shortLabel: '07'),
    AchievementDef(id: 'streak_14', title: 'Fortnight', category: 'consistency', shortLabel: '14'),
    AchievementDef(id: 'streak_30', title: '30-day line', category: 'consistency', shortLabel: '30d'),
    AchievementDef(id: 'active_50', title: '50 active days', category: 'consistency', shortLabel: '50'),
    AchievementDef(id: 'perfect_week', title: 'Perfect week', category: 'consistency', shortLabel: '7/7'),
    AchievementDef(id: 'full_field', title: 'Year in motion', category: 'consistency', shortLabel: '365'),
    AchievementDef(id: 'full_field_52w', title: 'Full field', category: 'consistency', shortLabel: '52W'),

    // Commitment
    AchievementDef(id: 'keep_promise', title: 'Keep a promise', category: 'commitment', shortLabel: 'PLAN'),

    // Forecast
    AchievementDef(id: 'beat_forecast', title: 'Beat the forecast', category: 'forecast', shortLabel: 'CALL'),

    // Social
    AchievementDef(id: 'first_nudge', title: 'First nudge', category: 'social', shortLabel: 'NUDGE'),
    AchievementDef(id: 'crew_of_five', title: 'Crew of five', category: 'social', shortLabel: 'CREW5'),
    AchievementDef(id: 'crew_carry', title: 'Crew carry', category: 'social', shortLabel: 'DUO'),
    AchievementDef(id: 'compare', title: 'Compare', category: 'social', shortLabel: 'VS'),

    // Squad
    AchievementDef(id: 'squad_founder', title: 'Squad founder', category: 'squad', shortLabel: 'SQUAD'),
    AchievementDef(id: 'squad_field', title: 'Squad field', category: 'squad', shortLabel: 'FIELD'),
    AchievementDef(id: 'mission_complete', title: 'Mission complete', category: 'squad', shortLabel: 'MISSION'),

    // Reflection
    AchievementDef(id: 'first_review', title: 'First weekly review', category: 'reflection', shortLabel: 'REVIEW'),
    AchievementDef(id: 'monthly_replay', title: 'Monthly replay', category: 'reflection', shortLabel: 'REPLAY'),

    // Comeback
    AchievementDef(id: 'comeback', title: 'Comeback commit', category: 'comeback', shortLabel: 'BACK'),
  ];

  static AchievementDef? byId(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// A user's unlocked achievement.
class UserAchievement {
  final String achievementId;
  final String userId;
  final DateTime unlockedAt;
  final Map<String, dynamic> metadata;

  const UserAchievement({
    required this.achievementId,
    required this.userId,
    required this.unlockedAt,
    this.metadata = const {},
  });

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      achievementId: map['achievementId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      unlockedAt: map['unlockedAt'] is DateTime
          ? map['unlockedAt'] as DateTime
          : DateTime.tryParse(map['unlockedAt'] as String? ?? '') ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'userId': userId,
      'unlockedAt': unlockedAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}
