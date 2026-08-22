import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../models/daily_stats.dart';

/// Deterministic forecast calculator.
///
/// Uses a transparent weighted-average algorithm based on the user's
/// recent 28-day history. No external AI models are called.
///
/// Algorithm:
/// 1. Collect last 28 days of daily stats.
/// 2. Filter to active days (totalPushUps > 0) for volume calculations.
/// 3. Calculate overall active-day average and recent 7-day average.
/// 4. Weight recent activity more strongly (62% recent, 38% overall).
/// 5. Estimate variance from the active-day distribution.
/// 6. Produce low, likely, high estimates and a confidence score.
///
/// Confidence depends on sample size, variance, and consistency.
class ForecastCalculator {
  const ForecastCalculator();

  /// Calculate forecast from daily stats.
  ///
  /// [dailyStats] should contain up to 28 days of history, ordered oldest-first.
  /// Returns null if insufficient data (fewer than 5 active days).
  ForecastResult? calculate(List<DailyStats> dailyStats) {
    final activeDays = dailyStats.where((d) => d.totalPushUps > 0).toList();

    if (activeDays.length < 5) return null;

    // Overall active-day average.
    final allValues = activeDays.map((d) => d.totalPushUps).toList();
    final overallAvg = allValues.reduce((a, b) => a + b) / allValues.length;

    // Recent 7-day average (from the most recent active days).
    final recentActive = activeDays.length >= 7
        ? activeDays.sublist(activeDays.length - 7)
        : activeDays;
    final recentValues = recentActive.map((d) => d.totalPushUps).toList();
    final recentAvg = recentValues.reduce((a, b) => a + b) / recentValues.length;

    // Weighted average favoring recent.
    final weighted = recentAvg * AppConstants.forecastRecentWeight +
        overallAvg * AppConstants.forecastBaseWeight;

    // Variance calculation.
    final mean = overallAvg;
    final variance = allValues.fold<double>(
          0.0,
          (sum, v) => sum + (v - mean) * (v - mean),
        ) /
        allValues.length;
    final stdDev = sqrt(variance);

    // Range.
    final low = max(0, (weighted - stdDev * 0.8).round());
    final high = (weighted + stdDev * 0.6).round();
    final likely = weighted.round();

    // Confidence: higher with more data, lower variance, and consistent behavior.
    final sampleFactor = min(1.0, activeDays.length / 21);
    final varianceFactor = max(0.0, 1.0 - (stdDev / mean).clamp(0.0, 1.0));
    final consistencyFactor =
        min(1.0, activeDays.length / dailyStats.length.clamp(1, 28));

    final rawConfidence =
        sampleFactor * 0.4 + varianceFactor * 0.35 + consistencyFactor * 0.25;
    final confidence = (rawConfidence * 100).round().clamp(45, 95);

    // Trend: compare recent vs overall.
    final trend = recentAvg > overallAvg
        ? ForecastTrend.up
        : recentAvg < overallAvg * 0.9
            ? ForecastTrend.down
            : ForecastTrend.stable;

    return ForecastResult(
      low: low,
      likely: likely,
      high: high,
      confidence: confidence,
      trend: trend,
      activeDaysUsed: activeDays.length,
      windowDays: dailyStats.length,
    );
  }
}

/// Result of forecast calculation.
class ForecastResult {
  final int low;
  final int likely;
  final int high;
  final int confidence;
  final ForecastTrend trend;
  final int activeDaysUsed;
  final int windowDays;

  const ForecastResult({
    required this.low,
    required this.likely,
    required this.high,
    required this.confidence,
    required this.trend,
    required this.activeDaysUsed,
    required this.windowDays,
  });

  String get rangeLabel => '$low–$high push-ups';
  String get likelyLabel => '$likely push-ups';
  String get confidenceLabel => '$confidence%';

  /// Meter fill ratio (0.0–1.0) for a bar of [segments] segments.
  int filledSegments(int segments) {
    if (high <= 0) return 0;
    return ((likely / high) * segments).round().clamp(0, segments);
  }
}

enum ForecastTrend { up, stable, down }
