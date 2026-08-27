import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

/// Notification service managing daily 10 PM push-up reminders and instant nudges.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Timer? _reminderTimer;

  /// Initialize system notification channels and timezones.
  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(initSettings);

      // Create Android Notification Channel (max importance with custom sound)
      const androidChannel = AndroidNotificationChannel(
        'repcommit_notifications_v3',
        'RepCommit Reminders & Nudges',
        description: 'Notifications for daily push-up reminders and friend nudges.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('climb'),
        enableVibration: true,
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(androidChannel);
        try {
          await androidImplementation.requestNotificationsPermission();
          await androidImplementation.requestExactAlarmsPermission();
        } catch (pe) {
          debugPrint('Notification permission request deferred until app restart: $pe');
        }
      }

      _initialized = true;
      debugPrint('NotificationService successfully initialized');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Show an immediate system notification (used for Nudges and Test Notifications).
  Future<void> showSystemNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await init();
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        try {
          await androidImplementation.requestNotificationsPermission();
        } catch (_) {}
      }

      const androidDetails = AndroidNotificationDetails(
        'repcommit_notifications_v3',
        'RepCommit Reminders & Nudges',
        channelDescription: 'Notifications for daily push-up reminders and friend nudges.',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('climb'),
        enableVibration: true,
        fullScreenIntent: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'climb.mp3',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        await _notificationsPlugin.show(
          id == 0 ? DateTime.now().millisecondsSinceEpoch ~/ 1000 : id,
          title,
          body,
          details,
        );
        debugPrint('System notification shown: $title - $body');
      } catch (soundErr) {
        debugPrint('Custom sound notification deferred, attempting default sound fallback: $soundErr');
        // Fallback without custom sound
        const fallbackAndroid = AndroidNotificationDetails(
          'repcommit_notifications_v3',
          'RepCommit Reminders & Nudges',
          channelDescription: 'Notifications for daily push-up reminders and friend nudges.',
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        );
        await _notificationsPlugin.show(
          id == 0 ? DateTime.now().millisecondsSinceEpoch ~/ 1000 : id,
          title,
          body,
          const NotificationDetails(android: fallbackAndroid),
        );
        debugPrint('Fallback system notification shown cleanly.');
      }
    } catch (e) {
      debugPrint('Failed to show system notification: $e');
    }
  }

  /// Check today's progress and schedule or cancel the 10 PM reminder.
  void updateDailyReminder(int todayTotal) {
    _reminderTimer?.cancel();
    if (todayTotal > 0) {
      debugPrint('Daily workout completed ($todayTotal reps). 10 PM reminder cleared.');
      return;
    }

    final now = DateTime.now();
    final target10PM = DateTime(now.year, now.month, now.day, 22, 0, 0);

    if (now.isBefore(target10PM)) {
      final timeUntil10PM = target10PM.difference(now);
      debugPrint('Scheduling 10 PM reminder in ${timeUntil10PM.inMinutes} minutes.');
      _reminderTimer = Timer(timeUntil10PM, () {
        showSystemNotification(
          id: 10001,
          title: '📢 10 PM Workout Reminder',
          body: "You haven't logged any workout sets today! Keep your streak active!",
        );
      });
    }
  }

  /// Trigger immediate 10 PM reminder test.
  Future<void> test10PMReminder() async {
    await showSystemNotification(
      id: 9999,
      title: '📢 10 PM Workout Reminder (Test)',
      body: "You haven't logged any workout sets today! Keep your streak active!",
    );
  }
}

