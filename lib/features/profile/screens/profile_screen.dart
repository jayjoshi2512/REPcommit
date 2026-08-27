import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/models/achievement.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../providers/app_providers.dart';
/// Profile screen — personal record, milestones, field notes, settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final statsCalc = ref.read(statsCalculatorProvider);

    // Calculate records from all daily stats.
    final allDays = state.dailyStats.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final records = statsCalc.records(allDays, bestSetValue: state.bestSetEver);
    final totalPushUps = allDays.fold<int>(0, (s, d) => s + d.totalPushUps);
    final activeDays = allDays.where((d) => d.totalPushUps > 0).length;
    final avgPerDay = activeDays > 0 ? (totalPushUps / activeDays).round() : 0;

    // Consistency from last 7 days.
    final now = DateTime.now();
    final last7 = <dynamic>[];
    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = date.toLocalDateString();
      last7.add(state.dailyStats[key]);
    }
    final consistencyPct = last7.isEmpty
        ? 0
        : (last7.where((d) => d != null && d.totalPushUps > 0).length / 7 * 100).round();

    final unlockedCount = state.unlockedAchievements.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 102),
      children: [
        // Profile header (non-sticky, scrollable)
        _ProfileHeader(
          totalPushUps: totalPushUps,
          username: state.username,
          displayName: state.displayName,
          photoUrl: state.photoUrl,
        ),
        // Structured stats grid
        _StatsGrid(
          activeDays: activeDays,
          avgPerDay: avgPerDay,
          consistencyPct: consistencyPct,
          currentStreak: state.currentStreak,
        ),
        // Structured personal records
        _PersonalRecordsSection(
          bestSet: records.bestSet,
          bestDay: records.bestDay,
          bestWeek: records.bestWeek,
          longestStreak: records.longestStreak,
          bestMonthActiveDays: records.bestMonthActiveDays,
        ),
        // Goals & Commitments
        const _GoalsSettingsSection(),
        // Milestones
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 0),
          child: Column(
            children: [
              SectionHeader(
                title: 'Milestones',
                trailing: '$unlockedCount unlocked · ${AchievementDef.all.length} total',
              ),
              const SizedBox(height: 9),
              _AchievementsGrid(unlocked: state.unlockedAchievements),
            ],
          ),
        ),
        // Danger Zone
        _DangerZone(),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final int totalPushUps;
  final String username;
  final String displayName;
  final String photoUrl;

  const _ProfileHeader({
    required this.totalPushUps,
    required this.username,
    required this.displayName,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final usernameStr = username.isEmpty ? 'user' : username;
    final nameStr = displayName.isNotEmpty ? displayName : '@$usernameStr';
    final initialStr = (nameStr.isNotEmpty ? nameStr[0] : '?').toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const KickerLabel('PROFILE'),
              const NotificationBell(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.signal,
                  border: Border.all(color: AppColors.lineStrong),
                ),
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            initialStr,
                            style: AppTypography.displaySmall.copyWith(
                              color: const Color(0xFF1B0F0B),
                              fontSize: 22,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initialStr,
                          style: AppTypography.displaySmall.copyWith(
                            color: const Color(0xFF1B0F0B),
                            fontSize: 22,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameStr,
                      style: AppTypography.heading.copyWith(
                        color: AppColors.ink,
                        fontSize: 22,
                        height: 1.0,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$usernameStr',
                      style: AppTypography.mono.copyWith(
                        color: AppColors.signal,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${totalPushUps.formatted} push-ups recorded',
                      style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int activeDays;
  final int avgPerDay;
  final int consistencyPct;
  final int currentStreak;

  const _StatsGrid({
    required this.activeDays,
    required this.avgPerDay,
    required this.consistencyPct,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Overview'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StructuredStatCard(
                  title: 'CURRENT STREAK',
                  value: '${currentStreak}d',
                  sub: 'consecutive active days',
                  accentColor: AppColors.signal,
                  icon: Icons.local_fire_department,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StructuredStatCard(
                  title: 'CONSISTENCY',
                  value: '$consistencyPct%',
                  sub: 'last 7 days active',
                  accentColor: AppColors.mint,
                  icon: Icons.ssid_chart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StructuredStatCard(
                  title: 'ACTIVE DAYS',
                  value: '$activeDays',
                  sub: 'total committed days',
                  accentColor: AppColors.ink,
                  icon: Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StructuredStatCard(
                  title: 'DAILY AVERAGE',
                  value: '$avgPerDay',
                  sub: 'reps per active day',
                  accentColor: AppColors.ink,
                  icon: Icons.equalizer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StructuredStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final Color accentColor;
  final IconData icon;

  const _StructuredStatCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.lineStrong),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.monoTiny.copyWith(
                  color: AppColors.inkFaint,
                  letterSpacing: 0.6,
                  fontSize: 9,
                ),
              ),
              Icon(icon, size: 14, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.ink,
              fontSize: 24,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: AppTypography.bodyTiny.copyWith(
              color: AppColors.inkFaint,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalRecordsSection extends StatelessWidget {
  final int bestSet;
  final int bestDay;
  final int bestWeek;
  final int longestStreak;
  final int bestMonthActiveDays;

  const _PersonalRecordsSection({
    required this.bestSet,
    required this.bestDay,
    required this.bestWeek,
    required this.longestStreak,
    required this.bestMonthActiveDays,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Personal Records'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border.all(color: AppColors.lineStrong),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _RecordCell(label: 'BEST SET', value: '$bestSet', sub: 'push-ups'),
                    _RecordCell(label: 'BEST DAY', value: '$bestDay', sub: 'push-ups'),
                    _RecordCell(label: 'BEST WEEK', value: '$bestWeek', sub: 'push-ups', isLast: true),
                  ],
                ),
                const Divider(height: 1, color: AppColors.line),
                Row(
                  children: [
                    _RecordCell(label: 'LONGEST LINE', value: '${longestStreak}d', sub: 'best streak'),
                    _RecordCell(label: 'BEST MONTH', value: '$bestMonthActiveDays', sub: 'active days'),
                    _RecordCell(label: 'ALL-TIME MAX', value: '$bestSet', sub: 'single set', isLast: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCell extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool isLast;
  const _RecordCell({required this.label, required this.value, required this.sub, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 11, 9, 11),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(right: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.monoTiny.copyWith(color: AppColors.inkFaint, letterSpacing: 0.6)),
            const SizedBox(height: 5),
            Text(value, style: AppTypography.statLarge.copyWith(color: AppColors.ink, fontSize: 18)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 7, color: AppColors.inkFaint)),
          ],
        ),
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  final Set<String> unlocked;
  const _AchievementsGrid({required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: AchievementDef.all.map((a) {
        final isUnlocked = unlocked.contains(a.id);
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 30 - 15) / 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border.all(
                color: isUnlocked ? const Color(0xFF4A554E) : AppColors.line,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Opacity(
              opacity: isUnlocked ? 1.0 : 0.42,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    a.shortLabel,
                    style: AppTypography.heading.copyWith(
                      color: isUnlocked ? AppColors.signal : AppColors.inkFaint,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.title,
                    style: TextStyle(fontSize: 7, height: 1.15, color: AppColors.inkFaint),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}



// ── Danger Zone ─────────────────────────────────────────────────

class _DangerZone extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            color: const Color(0xFF2A1A1A),
          ),
          const SizedBox(height: 16),
          Text(
            'DANGER ZONE',
            style: AppTypography.mono.copyWith(
              color: const Color(0xFF8B3A3A),
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Sign Out
          _DangerButton(
            label: 'SIGN OUT',
            subtitle: 'You can sign back in any time.',
            color: AppColors.inkFaint,
            onTap: () async {
              final confirmed = await _showConfirmDialog(
                context,
                title: 'Sign Out',
                message: 'Are you sure you want to sign out?',
                confirmLabel: 'SIGN OUT',
              );
              if (confirmed) {
                await ref.read(appStateProvider.notifier).signOut();
              }
            },
          ),
          const SizedBox(height: 6),
          // Delete All Data
          _DangerButton(
            label: 'DELETE ALL DATA',
            subtitle: 'Erases all push-up logs and stats. Your account stays.',
            color: const Color(0xFFE88A3A),
            onTap: () async {
              final confirmed = await _showConfirmDialog(
                context,
                title: 'Delete All Data',
                message: 'This will permanently delete all your push-up logs, daily stats, streaks, and records. Your account and username will be kept.\n\nThis cannot be undone.',
                confirmLabel: 'DELETE EVERYTHING',
                isDangerous: true,
              );
              if (confirmed) {
                await ref.read(appStateProvider.notifier).deleteAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data deleted.')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 6),
          // Delete Account
          _DangerButton(
            label: 'DELETE ACCOUNT',
            subtitle: 'Permanently removes your account, data, and username.',
            color: AppColors.signal,
            onTap: () async {
              final confirmed = await _showConfirmDialog(
                context,
                title: 'Delete Account',
                message: 'This will permanently delete:\n\n• All push-up logs and stats\n• Your username (@${ref.read(appStateProvider).username})\n• Your account\n\nThis cannot be undone.',
                confirmLabel: 'DELETE ACCOUNT',
                isDangerous: true,
              );
              if (confirmed) {
                await ref.read(appStateProvider.notifier).deleteAccount();
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool isDangerous = false,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C1A),
        shape: const RoundedRectangleBorder(),
        title: Text(
          title,
          style: AppTypography.heading.copyWith(color: AppColors.ink),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.inkFaint,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCEL',
              style: AppTypography.mono.copyWith(
                color: AppColors.inkFaint,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: AppTypography.mono.copyWith(
                color: isDangerous ? AppColors.signal : AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DangerButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.mono.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '→',
              style: TextStyle(fontSize: 14, color: color.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goals & Commitments Settings ──────────────────────────────────
class _GoalsSettingsSection extends ConsumerWidget {
  const _GoalsSettingsSection();

  void _showEditGoalModal(BuildContext context, WidgetRef ref, String title, String key, int currentValue) {
    final controller = TextEditingController(text: '$currentValue');
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.panel,
            border: Border(top: BorderSide(color: AppColors.lineStrong, width: 2)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UPDATE $title'.toUpperCase(),
                style: AppTypography.heading.copyWith(color: AppColors.ink, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Set your target push-up count for $title.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: AppTypography.title.copyWith(color: AppColors.ink, fontSize: 24),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Push-up Target',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.signal),
                  onPressed: () {
                    final parsed = int.tryParse(controller.text);
                    if (parsed != null && parsed > 0) {
                      final notifier = ref.read(appStateProvider.notifier);
                      if (key == 'daily') notifier.updateGoals(dailyTarget: parsed);
                      if (key == 'weekly') notifier.updateGoals(weeklyGoal: parsed);
                      if (key == 'longTerm') notifier.updateGoals(longTermGoal: parsed);
                    }
                    Navigator.pop(context);
                  },
                  child: Text('SAVE TARGET', style: AppTypography.heading.copyWith(color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Goals & Commitments'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border.all(color: AppColors.lineStrong),
            ),
            child: Column(
              children: [
                _GoalRow(
                  label: 'DAILY TARGET',
                  value: '${state.dailyTarget} push-ups / day',
                  sub: '${state.todayTotal} logged today (${(state.todayProgress * 100).round()}%)',
                  onTap: () => _showEditGoalModal(context, ref, 'Daily Target', 'daily', state.dailyTarget),
                ),
                const Divider(height: 1, color: AppColors.line),
                _GoalRow(
                  label: 'WEEKLY GOAL',
                  value: '${state.weeklyGoal} push-ups / week',
                  sub: '${state.thisWeekTotal} logged this week (${(state.weeklyProgress * 100).round()}%)',
                  onTap: () => _showEditGoalModal(context, ref, 'Weekly Goal', 'weekly', state.weeklyGoal),
                ),
                const Divider(height: 1, color: AppColors.line),
                _GoalRow(
                  label: 'LONG-TERM GOAL',
                  value: '${state.longTermGoal} total push-ups',
                  sub: '${state.allTimeTotal} logged all-time (${(state.longTermProgress * 100).round()}%)',
                  onTap: () => _showEditGoalModal(context, ref, 'Long-Term Goal', 'longTerm', state.longTermGoal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final VoidCallback onTap;

  const _GoalRow({
    required this.label,
    required this.value,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.kicker.copyWith(color: AppColors.signal, fontSize: 10)),
          const Icon(Icons.edit, size: 14, color: AppColors.inkFaint),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          Text(value, style: AppTypography.heading.copyWith(color: AppColors.ink, fontSize: 15)),
          const SizedBox(height: 2),
          Text(sub, style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint, fontSize: 11)),
        ],
      ),
    );
  }
}
