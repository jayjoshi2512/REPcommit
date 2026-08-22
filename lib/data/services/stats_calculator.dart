import '../models/daily_stats.dart';

/// Stats and consistency calculator.
///
/// Provides deterministic computation for:
/// - Consistency score (active days / eligible days)
/// - Streak (consecutive active days)
/// - Personal records (best set, best day, best week, longest streak)
/// - Momentum (last 7 days with comparison)
class StatsCalculator {
  const StatsCalculator();

  /// Calculate consistency for a window of days.
  ///
  /// Returns active days / total days as a percentage.
  ConsistencyResult consistency(List<DailyStats> days) {
    if (days.isEmpty) {
      return const ConsistencyResult(
        activeDays: 0,
        totalDays: 0,
        percentage: 0,
      );
    }

    final active = days.where((d) => d.totalPushUps > 0).length;
    final total = days.length;
    final pct = total > 0 ? (active / total * 100).round() : 0;

    return ConsistencyResult(
      activeDays: active,
      totalDays: total,
      percentage: pct,
    );
  }

  /// Calculate current streak from daily stats, ordered newest-first.
  int currentStreak(List<DailyStats> daysNewestFirst) {
    var streak = 0;
    for (final day in daysNewestFirst) {
      if (day.totalPushUps > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Calculate best streak from daily stats, ordered oldest-first.
  int bestStreak(List<DailyStats> daysOldestFirst) {
    var best = 0;
    var current = 0;
    for (final day in daysOldestFirst) {
      if (day.totalPushUps > 0) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }
    return best;
  }

  /// Calculate personal records from all daily stats.
  PersonalRecords records(List<DailyStats> allDays, {int? bestSetValue}) {
    if (allDays.isEmpty) return PersonalRecords.empty();

    // Best day
    int bestDay = 0;
    String bestDayDate = '';
    for (final day in allDays) {
      if (day.totalPushUps > bestDay) {
        bestDay = day.totalPushUps;
        bestDayDate = day.date;
      }
    }

    // Best week
    int bestWeek = 0;
    for (var i = 0; i <= allDays.length - 7; i++) {
      final weekTotal =
          allDays.sublist(i, i + 7).fold<int>(0, (sum, d) => sum + d.totalPushUps);
      if (weekTotal > bestWeek) bestWeek = weekTotal;
    }
    // Handle partial final week
    if (allDays.length < 7) {
      final total = allDays.fold<int>(0, (sum, d) => sum + d.totalPushUps);
      if (total > bestWeek) bestWeek = total;
    }

    // Best month (by active days)
    final monthMap = <String, int>{};
    for (final day in allDays) {
      if (day.totalPushUps > 0) {
        final monthKey = day.date.substring(0, 7); // YYYY-MM
        monthMap[monthKey] = (monthMap[monthKey] ?? 0) + 1;
      }
    }
    int bestMonthActiveDays = 0;
    for (final count in monthMap.values) {
      if (count > bestMonthActiveDays) bestMonthActiveDays = count;
    }

    // Longest streak
    final longest = bestStreak(allDays);

    return PersonalRecords(
      bestSet: bestSetValue ?? 0,
      bestDay: bestDay,
      bestDayDate: bestDayDate,
      bestWeek: bestWeek,
      longestStreak: longest,
      bestMonthActiveDays: bestMonthActiveDays,
    );
  }

  /// Last 7 days momentum with comparison to prior 7 days.
  MomentumResult momentum(List<DailyStats> last14Days) {
    final last7 = last14Days.length >= 7
        ? last14Days.sublist(last14Days.length - 7)
        : last14Days;
    final prior7 = last14Days.length >= 14
        ? last14Days.sublist(last14Days.length - 14, last14Days.length - 7)
        : <DailyStats>[];

    final currentTotal = last7.fold<int>(0, (sum, d) => sum + d.totalPushUps);
    final priorTotal = prior7.fold<int>(0, (sum, d) => sum + d.totalPushUps);
    final average = last7.isEmpty ? 0 : currentTotal ~/ last7.length;

    int changePercent = 0;
    if (priorTotal > 0) {
      changePercent = (((currentTotal - priorTotal) / priorTotal) * 100).round();
    }

    return MomentumResult(
      dailyValues: last7.map((d) => d.totalPushUps).toList(),
      average: average,
      changePercent: changePercent,
      currentTotal: currentTotal,
      priorTotal: priorTotal,
    );
  }
}

class ConsistencyResult {
  final int activeDays;
  final int totalDays;
  final int percentage;

  const ConsistencyResult({
    required this.activeDays,
    required this.totalDays,
    required this.percentage,
  });
}

class PersonalRecords {
  final int bestSet;
  final int bestDay;
  final String bestDayDate;
  final int bestWeek;
  final int longestStreak;
  final int bestMonthActiveDays;

  const PersonalRecords({
    required this.bestSet,
    required this.bestDay,
    required this.bestDayDate,
    required this.bestWeek,
    required this.longestStreak,
    required this.bestMonthActiveDays,
  });

  factory PersonalRecords.empty() => const PersonalRecords(
        bestSet: 0,
        bestDay: 0,
        bestDayDate: '',
        bestWeek: 0,
        longestStreak: 0,
        bestMonthActiveDays: 0,
      );
}

class MomentumResult {
  final List<int> dailyValues;
  final int average;
  final int changePercent;
  final int currentTotal;
  final int priorTotal;

  const MomentumResult({
    required this.dailyValues,
    required this.average,
    required this.changePercent,
    required this.currentTotal,
    required this.priorTotal,
  });
}
