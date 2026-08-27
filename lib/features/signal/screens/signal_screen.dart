import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/services/stats_calculator.dart';
import '../../../data/models/daily_stats.dart';
import '../../../data/models/exercise.dart';
import '../../../providers/app_providers.dart';
import '../../../core/widgets/exercise_filter_bar.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../today/widgets/heatmap_widget.dart';

/// Signal (Activity) screen.
///
/// Information hierarchy:
/// 1. Exercise Filter Bar
/// 2. Full-year commit field
/// 3. Week in selected exercise
/// 4. Personal records
/// 5. Weekly review
/// 6. Monthly replay
/// 7. Activity timeline
class SignalScreen extends ConsumerWidget {
  const SignalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final activeFilter = ref.watch(selectedExerciseFilterProvider);
    final exDef = activeFilter == 'all'
        ? ExerciseDef.pushups
        : ExerciseDef.fromId(activeFilter);

    final statsCalc = ref.read(statsCalculatorProvider);
    final now = DateTime.now();

    // Calculate records.
    final allDays = state.dailyStats.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final records = statsCalc.records(allDays, bestSetValue: state.bestSetEver);

    // Last 7 days for selected exercise.
    final last7 = <DailyStats>[];
    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = date.toLocalDateString();
      last7.add(state.dailyStats[key] ?? DailyStats.empty(key));
    }
    final weekTotal = last7.fold<int>(0, (s, d) => s + d.getTotalForExercise(activeFilter));

    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 102),
      children: [
        // Scrollable Signal Header
        _SignalHeader(weekTotal: weekTotal, exName: exDef.name),
        const SizedBox(height: 10),
        // Exercise Filter Bar
        const ExerciseFilterBar(mode: ExerciseFilterBarMode.userOnly),
        const SizedBox(height: 10),
        // Heatmap
        HeatmapWidget(
          trailingLabel: 'every day has a cell',
          onCellTap: (cell) {
            if (cell.isFuture) return;
          },
        ),
        const SizedBox(height: 13),
        // Week in exercise
        _WeekBars(last7: last7, weekTotal: weekTotal, exDef: exDef, activeFilter: activeFilter),
        const SizedBox(height: 13),
        // Records
        _RecordsGrid(records: records),
        const SizedBox(height: 13),
        // Weekly review card
        _WeeklyReviewCard(state: state),
        const SizedBox(height: 13),
        // Monthly replay
        _MonthlyReplay(state: state),
        const SizedBox(height: 13),
        // Activity timeline
        _ActivityTimeline(state: state, activeFilter: activeFilter, exDef: exDef),
      ],
    );
  }
}



class _SignalHeader extends StatelessWidget {
  final int weekTotal;
  final String exName;
  const _SignalHeader({required this.weekTotal, required this.exName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 14, 1, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KickerLabel('ACTIVITY HISTORY'),
                  const SizedBox(height: 4),
                  Text(
                    'All signal',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.ink,
                      fontSize: 28,
                      height: 1.0,
                      letterSpacing: -1.4,
                    ),
                  ),
                ],
              ),
              const NotificationBell(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'The raw trail of your effort · $weekTotal ${exName.toLowerCase()} this week',
            style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  final List<DailyStats> last7;
  final int weekTotal;
  final ExerciseDef exDef;
  final String activeFilter;

  const _WeekBars({
    required this.last7,
    required this.weekTotal,
    required this.exDef,
    required this.activeFilter,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = last7
        .map((d) => d.getTotalForExercise(activeFilter))
        .fold<int>(0, (a, b) => a > b ? a : b)
        .clamp(1, 999);
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SectionHeader(title: 'Week in ${exDef.name.toLowerCase()}', trailing: '$weekTotal reps'),
          const SizedBox(height: 10),
          SizedBox(
            height: 74,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(last7.length, (i) {
                final value = last7[i].getTotalForExercise(activeFilter);
                final height = maxVal > 0
                    ? (value / maxVal * 100).clamp(12, 100).toDouble()
                    : 12.0;
                final isToday = i == last7.length - 1;
                final date = now.subtract(Duration(days: 6 - i));
                final label = date.shortDayLabel;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 6 ? 5 : 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: height / 100,
                            child: Container(
                              color: isToday ? exDef.color : AppColors.mint,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(label, style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsGrid extends StatelessWidget {
  final PersonalRecords records;
  const _RecordsGrid({required this.records});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _RecordCell(label: 'BEST SET', value: '${records.bestSet}', sub: 'push-ups'),
          _RecordCell(label: 'BEST DAY', value: '${records.bestDay}', sub: 'push-ups'),
          _RecordCell(label: 'BEST WEEK', value: '${records.bestWeek}', sub: 'push-ups'),
          _RecordCell(label: 'LONGEST LINE', value: '${records.longestStreak}', sub: 'days', isLast: true),
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
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(right: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.monoTiny.copyWith(color: AppColors.inkFaint, letterSpacing: 0.6)),
            const SizedBox(height: 6),
            Text(value, style: AppTypography.statLarge.copyWith(color: AppColors.ink, fontSize: 19)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 7, color: AppColors.inkFaint)),
          ],
        ),
      ),
    );
  }
}

class _WeeklyReviewCard extends StatelessWidget {
  final AppState state;
  const _WeeklyReviewCard({required this.state});

  @override
  Widget build(BuildContext context) {
    // Compute real weekly stats.
    final now = DateTime.now();
    int activeDays = 0;
    int weekTotal = 0;
    int bestDayTotal = 0;
    String bestDayName = '';
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
      final stats = state.dailyStats[key];
      if (stats != null && stats.totalPushUps > 0) {
        activeDays++;
        weekTotal += stats.totalPushUps;
        if (stats.totalPushUps > bestDayTotal) {
          bestDayTotal = stats.totalPushUps;
          bestDayName = dayNames[(day.weekday - 1) % 7];
        }
      }
    }

    final dateStr = '${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SectionHeader(title: 'Weekly review', trailing: '$dateStr · current'),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$activeDays / 7', style: AppTypography.displayLarge.copyWith(color: AppColors.ink)),
                const SizedBox(width: 8),
                Text('days committed', style: TextStyle(fontSize: 8, color: AppColors.inkFaint)),
              ],
            ),
          ),
          _ReviewRow(label: 'Volume', value: '$weekTotal push-ups'),
          _ReviewRow(label: 'Best day', value: bestDayName.isEmpty ? 'No data yet' : '$bestDayName · $bestDayTotal'),
          _ReviewRow(label: 'Avg / day', value: activeDays > 0 ? '${(weekTotal / activeDays).round()} push-ups' : '—'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              activeDays >= 5
                  ? 'Strong week. Keep building momentum.'
                  : activeDays >= 3
                      ? 'Solid start. Add one more active day next week.'
                      : 'Every push-up counts. Start small and build.',
              style: AppTypography.bodyTiny.copyWith(color: AppColors.inkDim),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 8, color: AppColors.inkFaint)),
          Text(value, style: TextStyle(fontSize: 8, color: AppColors.ink, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MonthlyReplay extends StatelessWidget {
  final AppState state;
  const _MonthlyReplay({required this.state});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    // Compute this month's stats from dailyStats.
    int monthTotal = 0;
    int monthActiveDays = 0;
    int bestStreak = 0;
    int currentStreak = 0;

    for (int day = 1; day <= now.day; day++) {
      final key = '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${day.toString().padLeft(2, '0')}';
      final stats = state.dailyStats[key];
      if (stats != null && stats.totalPushUps > 0) {
        monthTotal += stats.totalPushUps;
        monthActiveDays++;
        currentStreak++;
        if (currentStreak > bestStreak) bestStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.lineStrong),
          bottom: BorderSide(color: AppColors.lineStrong),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KickerLabel('${months[now.month - 1]} / commit replay'),
          const SizedBox(height: 7),
          Text(
            'This is what showing up looked like.',
            style: AppTypography.displaySmall.copyWith(color: AppColors.ink, fontSize: 23, height: 0.95, letterSpacing: -1.0),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Text('$monthTotal', style: AppTypography.statLarge.copyWith(color: AppColors.ink, fontSize: 18)),
              const SizedBox(width: 5),
              Text('push-ups', style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint)),
              const SizedBox(width: 16),
              Text('$monthActiveDays', style: AppTypography.statLarge.copyWith(color: AppColors.ink, fontSize: 18)),
              const SizedBox(width: 5),
              Text('active days', style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint)),
              const SizedBox(width: 16),
              Text('${bestStreak}d', style: AppTypography.statLarge.copyWith(color: AppColors.ink, fontSize: 18)),
              const SizedBox(width: 5),
              Text('best line', style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint)),
            ],
          ),
          const SizedBox(height: 11),
          GestureDetector(
            onTap: () => _showMonthlyReplaySheet(
              context,
              months[now.month - 1],
              monthTotal,
              monthActiveDays,
              bestStreak,
              now,
              state,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              decoration: BoxDecoration(border: Border.all(color: AppColors.signal)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PLAY ${months[now.month - 1].toUpperCase()}',
                    style: AppTypography.mono.copyWith(color: AppColors.signal, fontWeight: FontWeight.w800, fontSize: 8),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.play_arrow, size: 12, color: AppColors.signal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthlyReplaySheet(
    BuildContext context,
    String monthName,
    int monthTotal,
    int activeDays,
    int bestStreak,
    DateTime now,
    AppState state,
  ) {
    final daysPassed = now.day;
    final avgPerActiveDay = activeDays > 0 ? (monthTotal / activeDays).round() : 0;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101311),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.lineStrong),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$monthName Replay',
                    style: AppTypography.displaySmall.copyWith(color: AppColors.ink),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.inkFaint, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$monthTotal push-ups across $activeDays active days in $monthName.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint),
              ),
              const SizedBox(height: 20),
              // Stats breakdown row
              Row(
                children: [
                  Expanded(
                    child: _ReplayStatCard(label: 'TOTAL PUSH-UPS', value: '$monthTotal'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ReplayStatCard(label: 'ACTIVE DAYS', value: '$activeDays / $daysPassed'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ReplayStatCard(label: 'BEST STREAK', value: '${bestStreak}d'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ReplayStatCard(label: 'AVG / ACTIVE DAY', value: '$avgPerActiveDay'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.signal,
                    foregroundColor: const Color(0xFF160D09),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CLOSE REPLAY',
                    style: AppTypography.mono.copyWith(fontWeight: FontWeight.w900, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReplayStatCard extends StatelessWidget {
  final String label;
  final String value;
  const _ReplayStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint)),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.title.copyWith(color: AppColors.ink, fontSize: 18)),
        ],
      ),
    );
  }
}

class _ActivityTimeline extends StatelessWidget {
  final AppState state;
  final String activeFilter;
  final ExerciseDef exDef;

  const _ActivityTimeline({
    required this.state,
    required this.activeFilter,
    required this.exDef,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Build recent activity rows.
    final rows = <_ActivityRow>[];
    for (var i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final key = date.toLocalDateString();
      final stats = state.dailyStats[key];
      final total = stats?.getTotalForExercise(activeFilter) ?? 0;
      if (total <= 0) continue;

      rows.add(_ActivityRow(
        day: date.day.toString().padLeft(2, '0'),
        month: [
          'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
          'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
        ][date.month - 1],
        label: date.relativeLabel,
        detail: '${exDef.name} set · ${stats?.lastLoggedAt?.formattedTime ?? '9:41 PM'}',
        amount: total,
        unitLabel: exDef.name.toLowerCase(),
        exColor: exDef.color,
        isFirst: rows.isEmpty,
      ));
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.lineStrong)),
        color: AppColors.panel,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 9),
            child: Text(
              'RECENT ${exDef.name.toUpperCase()} SETS',
              style: AppTypography.kicker.copyWith(color: AppColors.inkFaint),
            ),
          ),
          Container(height: 1, color: AppColors.line),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No ${exDef.name.toLowerCase()} logged recently.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint, fontSize: 11),
              ),
            )
          else
            ...rows,
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String day;
  final String month;
  final String label;
  final String detail;
  final int amount;
  final String unitLabel;
  final Color exColor;
  final bool isFirst;

  const _ActivityRow({
    required this.day,
    required this.month,
    required this.label,
    required this.detail,
    required this.amount,
    this.unitLabel = 'reps',
    this.exColor = AppColors.mint,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          // Date column with timeline dot.
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day, style: AppTypography.statLarge.copyWith(color: AppColors.ink, fontSize: 18)),
                const SizedBox(height: 4),
                Text(month, style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.heading.copyWith(color: AppColors.ink, fontSize: 12)),
                const SizedBox(height: 5),
                Text(detail, style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+$amount',
                style: AppTypography.statLarge.copyWith(color: exColor, fontSize: 19),
              ),
              const SizedBox(height: 4),
              Text(unitLabel, style: AppTypography.monoTiny.copyWith(color: AppColors.inkFaint)),
            ],
          ),
        ],
      ),
    );
  }
}
