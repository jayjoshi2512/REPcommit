import 'dart:math';

import '../models/daily_stats.dart';
import '../models/push_log.dart';

/// Generates synthetic demo data for development.
///
/// All demo data is clearly isolated. In production, this seeder
/// is not invoked — Firebase is the sole data source.
class DemoDataSeeder {
  final Random _rng = Random(42); // Deterministic seed for consistent demo.

  /// Generate daily stats for the past [days] days.
  Map<String, DailyStats> generateDailyStats({int days = 180}) {
    final now = DateTime.now();
    final stats = <String, DailyStats>{};

    for (var i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = _dateKey(date);

      // ~14% chance of a rest day.
      if (_rng.nextDouble() < 0.14) {
        stats[key] = DailyStats.empty(key);
        continue;
      }

      // Base volume with some wave pattern.
      final wave = (sin(i * 0.31) + 1) / 2;
      final base = 10 + _rng.nextInt(48) + (wave * 30).round();
      final bonus = i % 11 == 0 ? 35 : 0;
      final total = base + bonus;

      // 1–3 sessions per day.
      final sessions = 1 + _rng.nextInt(3);
      final firstTime = DateTime(date.year, date.month, date.day,
          18 + _rng.nextInt(4), _rng.nextInt(60));

      stats[key] = DailyStats(
        date: key,
        totalPushUps: total,
        sessionCount: sessions,
        firstLoggedAt: firstTime,
        lastLoggedAt: firstTime.add(Duration(minutes: 10 + _rng.nextInt(30))),
        target: 60,
        targetReached: total >= 60,
        createdAt: date,
        updatedAt: date,
      );
    }

    return stats;
  }

  /// Generate push logs for today.
  List<PushLog> generateTodayLogs({
    required String userId,
    required int todayTotal,
  }) {
    final now = DateTime.now();
    final key = _dateKey(now);

    if (todayTotal <= 0) return [];

    // Split into 1–2 sessions.
    final first = (todayTotal * 0.45).round().clamp(5, todayTotal);
    final second = todayTotal - first;

    final logs = <PushLog>[
      PushLog(
        id: 'demo_today_1',
        userId: userId,
        amount: first,
        loggedAt: DateTime(now.year, now.month, now.day, 20, 10),
        localDate: key,
        timezone: 'Asia/Kolkata',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    if (second > 0) {
      logs.add(PushLog(
        id: 'demo_today_2',
        userId: userId,
        amount: second,
        loggedAt: DateTime(now.year, now.month, now.day, 20, 31),
        localDate: key,
        timezone: 'Asia/Kolkata',
        createdAt: now,
        updatedAt: now,
      ));
    }

    return logs;
  }

  /// Generate demo friend data.
  List<DemoFriend> generateFriends() {
    return const [
      DemoFriend(username: 'byte_pusher', streak: 14, todayPushUps: 61, isOnline: true),
      DemoFriend(username: 'sudo_flex', streak: 21, todayPushUps: 74, isOnline: true),
      DemoFriend(username: 'kernel_panic', streak: 2, todayPushUps: 33, isOnline: false),
      DemoFriend(username: 'ctrl_alt_flex', streak: 17, todayPushUps: 57, isOnline: true),
      DemoFriend(username: 'null_gains', streak: 6, todayPushUps: 48, isOnline: false),
      DemoFriend(username: 'stack_overflow', streak: 9, todayPushUps: 52, isOnline: true),
    ];
  }

  /// Generate demo requests.
  List<DemoRequest> generateRequests() {
    return const [
      DemoRequest(username: 'react_ranger', message: 'wants to join your crew', initial: 'R'),
      DemoRequest(username: 'loop_hero', message: 'sent 2h ago', initial: 'L'),
      DemoRequest(username: 'dev_flex', message: 'sent yesterday', initial: 'D'),
    ];
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

/// Demo friend (not a Firestore model — development only).
class DemoFriend {
  final String username;
  final int streak;
  final int todayPushUps;
  final bool isOnline;

  const DemoFriend({
    required this.username,
    required this.streak,
    required this.todayPushUps,
    required this.isOnline,
  });
}

class DemoRequest {
  final String username;
  final String message;
  final String initial;

  const DemoRequest({
    required this.username,
    required this.message,
    required this.initial,
  });
}

