import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

import '../../../core/widgets/shared_widgets.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/models/daily_stats.dart';

import '../../../data/models/exercise.dart';
import '../../../core/widgets/exercise_filter_bar.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../providers/app_providers.dart';
import '../widgets/heatmap_widget.dart';

/// Today screen — the primary dashboard.
///
/// Information hierarchy:
/// 1. Thought of the Day
/// 2. Today's Commitment
/// 3. Push-ups Today instrument
/// 4. Log a Push button
/// 5. Commit Field (heatmap)
/// 6. Forecast
/// 7. Momentum
/// 8. Consistency
/// 9. Weekly Review strip
/// 10. Ghost commit / comeback
/// 11. Crew pulse
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final now = DateTime.now();

    // Comeback mode is dynamic: only show if user has past push-up history, 0 streak, and 0 today.
    final hasPastHistory = state.dailyStats.values.any((d) => d.totalPushUps > 0);
    final showComeback = hasPastHistory && state.currentStreak == 0 && state.todayTotal == 0;

    return Column(
      children: [
        // Top bar
        _TopBar(state: state),
        // Scrollable content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 102),
            children: [
              // Today heading
              _TodayHead(now: now, state: state),
              const SizedBox(height: 10),
              // Exercise Filter Bar
              const ExerciseFilterBar(mode: ExerciseFilterBarMode.today),
              const SizedBox(height: 13),
              // Comeback (conditionally dynamic)
              if (showComeback)
                Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: _ComebackStrip(ref: ref),
                ),
              // Workout instrument
              _PushInstrument(state: state),
              const SizedBox(height: 13),
              // Goals circular progress card
              _GoalsProgressCard(state: state),
              const SizedBox(height: 13),
              // Heatmap
              HeatmapWidget(
                onCellTap: (cell) => _openDayView(context, cell),
              ),
              const SizedBox(height: 13),
              // Momentum
              _MomentumSection(state: state, ref: ref),
              const SizedBox(height: 13),
              // Crew pulse
              _CrewPulse(state: state),
            ],
          ),
        ),
      ],
    );
  }

  void _openDayView(BuildContext context, dynamic cell) {
    if (cell.isFuture) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xC7050606),
      builder: (_) => _DayViewSheet(cell: cell),
    );
  }
}
// ── Top Bar ─────────────────────────────────────────────────────
class _TopBar extends ConsumerWidget {
  final AppState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const BrandMark(),
              const SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REPCOMMIT',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.signal,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _getGreeting(),
                    style: AppTypography.title.copyWith(color: AppColors.ink),
                  ),
                ],
              ),
            ],
          ),
          const NotificationBell(),
        ],
      ),
    );
  }
}

// ── Today Head ──────────────────────────────────────────────────
class _TodayHead extends StatelessWidget {
  final DateTime now;
  final AppState state;
  const _TodayHead({required this.now, required this.state});

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final usernameStr = state.username.isEmpty ? 'user' : state.username;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KickerLabel('${now.day} ${months[now.month - 1]} · ${weekdays[now.weekday - 1]} · '),
                  Text(
                    '@$usernameStr',
                    style: AppTypography.kicker.copyWith(
                      color: AppColors.signal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Today's signal",
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.ink,
                  fontSize: 26,
                  height: 1.0,
                  letterSpacing: -1.2,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 110,
            child: Text(
              'One action moves the dashboard.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint, fontSize: 10),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}





// ── Comeback Strip ──────────────────────────────────────────────
class _ComebackStrip extends StatelessWidget {
  final WidgetRef ref;
  const _ComebackStrip({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.signal),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1210), Color(0xFF121514)],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MicroLabel('comeback mode'),
                const SizedBox(height: 4),
                Text(
                  "You're back.",
                  style: AppTypography.titleSmall.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your last commit was a few days ago. Start with the smallest useful win.',
                  style: TextStyle(fontSize: 8, color: AppColors.inkFaint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              ref.read(appStateProvider.notifier).logPushUps(15);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('+15 push-ups logged')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              color: AppColors.signal,
              child: Text(
                '15 PUSH-UPS',
                style: AppTypography.mono.copyWith(
                  color: const Color(0xFF160D09),
                  fontWeight: FontWeight.w900,
                  fontSize: 7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Push / Workout Instrument ───────────────────────────────────
class _PushInstrument extends ConsumerWidget {
  final AppState state;
  const _PushInstrument({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(selectedExerciseFilterProvider);
    final exDef = activeFilter == 'all'
        ? const ExerciseDef(
            id: 'all',
            name: 'Total Reps',
            icon: Icons.flash_on,
            color: AppColors.signal,
          )
        : ExerciseDef.fromId(activeFilter);

    final exerciseTotalToday = state.getTodayTotalFor(activeFilter);
    final progress = state.dailyTarget > 0 ? (exerciseTotalToday / state.dailyTarget).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();

    // Calculate weekly consistency (last 7 days active)
    final now = DateTime.now();
    int activeDaysThisWeek = 0;
    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      final daily = state.dailyStats[key];
      if (daily != null && daily.getTotalForExercise(activeFilter) > 0) {
        activeDaysThisWeek++;
      }
    }
    final consistencyPct = (activeDaysThisWeek / 7 * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.lineStrong),
      ),
      padding: const EdgeInsets.all(14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: readout & progress
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MicroLabel('${exDef.name.toLowerCase()} today'),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$exerciseTotalToday',
                        style: AppTypography.displayHero.copyWith(color: AppColors.ink),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        exDef.name.toUpperCase(),
                        style: AppTypography.mono.copyWith(
                          color: exDef.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  Container(
                    height: 6,
                    color: const Color(0xFF232724),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(color: exDef.color),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Progress status line at bottom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state.targetReached ? 'GOAL HIT' : 'PROGRESS',
                        style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint),
                      ),
                      Text(
                        '$pct%',
                        style: AppTypography.monoSmall.copyWith(
                          color: state.targetReached ? AppColors.mint : AppColors.signal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Right: side stats panel
            Container(
              width: 115,
              margin: const EdgeInsets.only(left: 14),
              padding: const EdgeInsets.only(left: 14),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SideStat(value: '${state.currentStreak}', label: 'DAY STREAK'),
                  Container(height: 1, color: AppColors.line),
                  _SideStat(value: '${state.bestStreak}', label: 'BEST STREAK'),
                  Container(height: 1, color: AppColors.line),
                  _SideStat(value: '$consistencyPct%', label: 'CONSISTENCY'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideStat extends StatelessWidget {
  final String value;
  final String label;
  const _SideStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypography.statLarge.copyWith(color: AppColors.ink)),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint, fontSize: 8),
        ),
      ],
    );
  }
}



// ── Momentum ────────────────────────────────────────────────────
class _MomentumSection extends StatelessWidget {
  final AppState state;
  final WidgetRef ref;
  const _MomentumSection({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final statsCalc = ref.read(statsCalculatorProvider);
    final now = DateTime.now();

    // Get last 14 days.
    final days14 = <DailyStats>[];
    for (var i = 13; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      days14.add(state.dailyStats[key] ?? DailyStats.empty(key));
    }

    final momentum = statsCalc.momentum(days14);
    final maxVal = momentum.dailyValues.isEmpty
        ? 75
        : momentum.dailyValues.reduce((a, b) => a > b ? a : b).clamp(1, 999);

    return Column(
      children: [
        const SectionHeader(title: 'Momentum', trailing: 'last 7 days'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.fromLTRB(11, 12, 11, 10),
          child: Column(
            children: [
              // Bars
              SizedBox(
                height: 74,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(
                    momentum.dailyValues.length,
                    (i) {
                      final value = momentum.dailyValues[i];
                      final height = maxVal > 0
                          ? (value / maxVal * 100).clamp(12, 100).toDouble()
                          : 12.0;
                      final isToday = i == momentum.dailyValues.length - 1;
                      final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      final dayOffset = now.weekday - momentum.dailyValues.length + i;
                      final label = dayLabels[((dayOffset % 7) + 7) % 7];

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
                                    color: isToday ? AppColors.signal : AppColors.mint,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: AppTypography.monoSmall.copyWith(
                                  color: AppColors.inkFaint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '7d avg ${momentum.average} push-ups',
                      style: AppTypography.mono.copyWith(color: AppColors.inkFaint),
                    ),
                    Text(
                      '${momentum.changePercent >= 0 ? '+' : ''}${momentum.changePercent}% vs prior',
                      style: AppTypography.mono.copyWith(
                        color: momentum.changePercent >= 0 ? AppColors.mint : AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}



// ── Crew Pulse ──────────────────────────────────────────────────
class _CrewPulse extends StatelessWidget {
  final AppState state;
  const _CrewPulse({required this.state});

  @override
  Widget build(BuildContext context) {
    final visible = state.friends.take(3).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final activeCount = state.friends.where((f) => (f['isOnline'] as bool?) ?? false).length;

    return Column(
      children: [
        SectionHeader(
          title: 'Crew pulse',
          trailing: '$activeCount pushing today',
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: visible.asMap().entries.map((entry) {
              final i = entry.key;
              final f = entry.value;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    border: i < visible.length - 1
                        ? const Border(right: BorderSide(color: AppColors.line))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.panel3,
                              border: Border.all(color: AppColors.lineStrong),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              ((f['username'] as String?) ?? '?')[0].toUpperCase(),
                              style: AppTypography.mono.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 8,
                              ),
                            ),
                          ),
                          Text(
                            ((f['isOnline'] as bool?) ?? false) ? 'LIVE' : 'OFF',
                            style: AppTypography.monoTiny.copyWith(
                              color: AppColors.inkFaint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(f['todayPushUps'] as int?) ?? 0}',
                        style: AppTypography.statMedium.copyWith(color: AppColors.ink),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '@${(f['username'] as String?) ?? ''}',
                        style: TextStyle(
                          fontSize: 8,
                          color: AppColors.inkFaint,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Day View Sheet ──────────────────────────────────────────────
class _DayViewSheet extends StatelessWidget {
  final dynamic cell;
  const _DayViewSheet({required this.cell});

  @override
  Widget build(BuildContext context) {
    final date = cell.date as DateTime;
    final value = cell.value as int;

    return Container(
      color: AppColors.panel,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KickerLabel(date.dayModalLabel),
                  const SizedBox(height: 4),
                  Text(
                    value > 0 ? 'A $value-push-up day.' : 'An empty square.',
                    style: AppTypography.displaySmall.copyWith(color: AppColors.ink),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  '×',
                  style: TextStyle(fontSize: 20, color: AppColors.inkFaint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Total
          Text(
            '$value',
            style: AppTypography.displayXL.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 5),
          Text(
            value > 0
                ? 'push-ups · ${(value * 0.38).round() > 0 ? 2 : 0} logged sets'
                : 'No push-ups logged on this day.',
            style: TextStyle(fontSize: 8, color: AppColors.inkFaint),
          ),
          if (value > 0) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: AppColors.line),
            _DayEvent(time: '08:10 PM', amount: (value * 0.38).round().clamp(5, value)),
            _DayEvent(time: '08:31 PM', amount: value - (value * 0.38).round().clamp(5, value)),
            const SizedBox(height: 12),
            Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.mint, width: 2)),
                color: AppColors.panel2,
              ),
              padding: const EdgeInsets.all(10),
              child: Text(
                'You usually do more when you start before 9 PM.',
                style: AppTypography.bodyTiny.copyWith(
                  color: AppColors.inkDim,
                  height: 1.45,
                ),
              ),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}

class _DayEvent extends StatelessWidget {
  final String time;
  final int amount;
  const _DayEvent({required this.time, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$amount push-ups',
                  style: AppTypography.heading.copyWith(color: AppColors.ink, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'push-up set',
                  style: TextStyle(fontSize: 7, color: AppColors.inkFaint),
                ),
              ],
            ),
          ),
          Text(
            'logged',
            style: TextStyle(fontSize: 7, color: AppColors.inkFaint),
          ),
        ],
      ),
    );
  }
}

// ── Goals Circular Progress Card ─────────────────────────────────
class _GoalsProgressCard extends StatelessWidget {
  final AppState state;
  const _GoalsProgressCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.lineStrong),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              painter: _TripleCircularProgressPainter(
                dailyProgress: state.todayProgress,
                weeklyProgress: state.weeklyProgress,
                longTermProgress: state.longTermProgress,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(state.todayProgress * 100).round()}%',
                      style: AppTypography.heading.copyWith(
                        color: AppColors.signal,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'TODAY',
                      style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint, fontSize: 8),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GoalStatRow(
                  color: AppColors.signal,
                  title: 'DAILY TARGET',
                  value: '${state.todayTotal} / ${state.dailyTarget}',
                  pct: '${(state.todayProgress * 100).round()}%',
                ),
                const SizedBox(height: 8),
                _GoalStatRow(
                  color: const Color(0xFF00E676),
                  title: 'WEEKLY GOAL',
                  value: '${state.thisWeekTotal} / ${state.weeklyGoal}',
                  pct: '${(state.weeklyProgress * 100).round()}%',
                ),
                const SizedBox(height: 8),
                _GoalStatRow(
                  color: const Color(0xFF00B0FF),
                  title: 'LONG-TERM GOAL',
                  value: '${state.allTimeTotal} / ${state.longTermGoal}',
                  pct: '${(state.longTermProgress * 100).round()}%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStatRow extends StatelessWidget {
  final Color color;
  final String title;
  final String value;
  final String pct;

  const _GoalStatRow({
    required this.color,
    required this.title,
    required this.value,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppTypography.kicker.copyWith(color: color, fontSize: 9)),
                  Text(pct, style: AppTypography.monoSmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 1),
              Text(value, style: AppTypography.bodySmall.copyWith(color: AppColors.inkDim, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripleCircularProgressPainter extends CustomPainter {
  final double dailyProgress;
  final double weeklyProgress;
  final double longTermProgress;

  _TripleCircularProgressPainter({
    required this.dailyProgress,
    required this.weeklyProgress,
    required this.longTermProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 5.0;

    void drawRing(double radius, double progress, Color color) {
      final bgPaint = Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawCircle(center, radius, bgPaint);
      if (progress > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -1.5708,
          6.28318 * progress,
          false,
          fgPaint,
        );
      }
    }

    drawRing(size.width / 2 - 4, dailyProgress, AppColors.signal);
    drawRing(size.width / 2 - 13, weeklyProgress, const Color(0xFF00E676));
    drawRing(size.width / 2 - 22, longTermProgress, const Color(0xFF00B0FF));
  }

  @override
  bool shouldRepaint(covariant _TripleCircularProgressPainter oldDelegate) {
    return oldDelegate.dailyProgress != dailyProgress ||
        oldDelegate.weeklyProgress != weeklyProgress ||
        oldDelegate.longTermProgress != longTermProgress;
  }
}

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return 'Good morning.';
  } else if (hour >= 12 && hour < 17) {
    return 'Good noon.';
  } else if (hour >= 17 && hour < 22) {
    return 'Good evening.';
  } else {
    return 'Late night.';
  }
}

