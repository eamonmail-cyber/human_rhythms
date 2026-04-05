import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/routine.dart';

class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'hr_reminders';
  static const _channelName = 'Human Rhythms Reminders';
  static const _channelDesc = 'Daily routine and wellness reminders';

  // Notification ID ranges
  static const _routineBase = 1000;
  static const _streakId = 2000;
  static const _weeklySummaryId = 2001;

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(initSettings);

    // Create Android notification channel
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );
  }

  static Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      // requestNotificationsPermission() only exists on Android 13+
      // On Android 10 and below notifications are granted by default
      if (await Permission.notification.isGranted) return true;
      final result = await android.requestNotificationsPermission();
      return result ?? true; // null means pre-Android 13 = granted by default
    }
    return true;
  }

  // ── 1. Routine Reminder ───────────────────────────────────────────────────

  static Future<void> scheduleRoutineReminder(Routine r, int index) async {
    if (r.targetTime == null) return;
    final parts = r.targetTime!.split(':');
    if (parts.length < 2) return;
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;

    // Compute the exact scheduled time for logging
    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    debugPrint(
        '[ReminderService] Scheduled reminder for ${r.title} at $scheduledTime');

    final messages = [
      'Time for ${r.title}',
      'Your ${r.title} is scheduled for now',
      'You usually feel better after ${r.title} — time to do it',
    ];

    await _scheduleDaily(
      id: _routineBase + index,
      title: 'Human Rhythms',
      body: messages[index % messages.length],
      hour: hour,
      minute: minute,
      vibrationPattern: Int64List.fromList([0, 250]),
    );
  }

  // ── 2. Streak Reminder (8pm if nothing logged today) ─────────────────────

  static Future<void> scheduleStreakReminder(int currentStreak) async {
    await _scheduleDaily(
      id: _streakId,
      title: 'Human Rhythms',
      body: currentStreak > 0
          ? 'You have logged routines $currentStreak days in a row. Keep it going.'
          : 'Log your routines today to keep your streak alive.',
      hour: 20,
      minute: 0,
      vibrationPattern: Int64List.fromList([0, 250]),
    );
  }

  // ── 3. Milestone Notification ─────────────────────────────────────────────

  static Future<void> notifyMilestone(int streak) async {
    final messages = {
      7: '7 days straight. Your consistency is building something real.',
      14: 'Two weeks. You are building a habit now.',
      21: '21 days. This is becoming who you are.',
      30: '30 days. Most people never make it here. You did.',
    };
    final msg = messages[streak];
    if (msg == null) return;

    await _plugin.show(
      3000 + streak,
      'Human Rhythms',
      msg,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  // ── 4. Weekly Summary (Sunday 7pm) ────────────────────────────────────────

  static Future<void> scheduleWeeklySummary() async {
    final mode = _resolveScheduleMode();
    final now = tz.TZDateTime.now(tz.local);
    final daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day + daysUntilSunday, 19, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    debugPrint('[ReminderService] Weekly summary scheduled for $scheduled '
        '(mode: $mode)');

    await _plugin.zonedSchedule(
      _weeklySummaryId,
      'Human Rhythms',
      'Your week in numbers is ready. Tap to see your insights.',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          vibrationPattern: Int64List.fromList([0, 250]),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  static Future<void> cancel(int id) => _plugin.cancel(id);
  static Future<void> cancelAll() => _plugin.cancelAll();
  static Future<void> cancelRoutineReminder(int index) =>
      _plugin.cancel(_routineBase + index);

  // ── Schedule-mode resolver ────────────────────────────────────────────────
  //
  // exactAllowWhileIdle works on all API levels (21+). The SCHEDULE_EXACT_ALARM
  // and USE_EXACT_ALARM permissions in AndroidManifest.xml cover API 31+.
  static AndroidScheduleMode _resolveScheduleMode() {
    return AndroidScheduleMode.exactAllowWhileIdle;
  }

  // ── Daily schedule helper ─────────────────────────────────────────────────

  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required Int64List vibrationPattern,
  }) async {
    final mode = _resolveScheduleMode();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          vibrationPattern: vibrationPattern,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
