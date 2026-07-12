import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  // Request permissions for Android 13+ and exact alarms
  Future<void> requestPermissions() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  // Schedule notification for a task
  Future<void> scheduleTaskNotification(Task task) async {
    // Cannot schedule in the past
    if (task.dateTime.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: task.id.hashCode,
      title: 'Task Reminder',
      body: 'It is time to: ${task.title}',
      scheduledDate: tz.TZDateTime.from(task.dateTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Notifications for task deadlines',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Cancel notification
  Future<void> cancelTaskNotification(String taskId) async {
    await flutterLocalNotificationsPlugin.cancel(id: taskId.hashCode);
  }

  // Schedule Daily Briefing at 7:00 AM
  Future<void> scheduleDailyBriefing() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      7,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 0, // Unique ID for daily briefing
      title: 'Chào ngày mới!',
      body: 'Đừng quên kiểm tra các nhiệm vụ cần làm hôm nay nhé.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_briefing',
          'Daily Briefing',
          channelDescription: 'Daily morning reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
    );
  }
}
