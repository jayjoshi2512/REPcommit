import 'dart:async';
import 'package:flutter/foundation.dart';

/// Notification service managing daily 10 PM push-up reminders.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  Timer? _reminderTimer;
  Timer? _monthlyTimer;

  /// Initialize and schedule check for 10 PM reminder & 1st of month 12 PM recap.
  Future<void> init() async {
    debugPrint('NotificationService initialized');
    scheduleMonthlyRecapNotification();
  }

  /// Check today's progress and schedule or cancel the 10 PM reminder.
  void updateDailyReminder(int todayTotal) {
    _reminderTimer?.cancel();
    if (todayTotal > 0) {
      debugPrint('Daily push-ups completed ($todayTotal). 10 PM reminder cleared.');
      return;
    }

    final now = DateTime.now();
    final target10PM = DateTime(now.year, now.month, now.day, 22, 0, 0);

    if (now.isBefore(target10PM)) {
      final timeUntil10PM = target10PM.difference(now);
      debugPrint('Scheduling 10 PM reminder in ${timeUntil10PM.inMinutes} minutes.');
      _reminderTimer = Timer(timeUntil10PM, () {
        _triggerNotification();
      });
    }

    scheduleMonthlyRecapNotification();
  }

  /// Schedule monthly recap notification for 12:00 PM on the 1st of every month.
  void scheduleMonthlyRecapNotification() {
    _monthlyTimer?.cancel();
    final now = DateTime.now();
    final isFirstOfDay = now.day == 1;

    final target12PM = DateTime(now.year, now.month, 1, 12, 0, 0);

    if (isFirstOfDay && now.isBefore(target12PM)) {
      final timeUntil12PM = target12PM.difference(now);
      debugPrint('Scheduling 1st of month 12 PM recap notification in ${timeUntil12PM.inMinutes} minutes.');
      _monthlyTimer = Timer(timeUntil12PM, () {
        debugPrint('📢 12 PM MONTHLY RECAP: Your monthly push-up recap is ready! Look back at last month\'s achievements!');
      });
    }
  }

  void _triggerNotification() {
    debugPrint('📢 10 PM REMINDER: You haven\'t logged push-ups today! Keep your line active!');
  }
}
