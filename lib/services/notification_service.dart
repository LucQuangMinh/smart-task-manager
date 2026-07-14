import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

// Top-level function for handling background notification actions
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fallback: If the user tapped the "Dismiss" action, forcefully cancel the notification
  if (notificationResponse.actionId == 'dismiss_action' && notificationResponse.id != null) {
    await FlutterLocalNotificationsPlugin().cancel(id: notificationResponse.id!);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

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

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'dismiss_action' && response.id != null) {
          await flutterLocalNotificationsPlugin.cancel(id: response.id!);
        } else if (response.payload != null) {
          selectNotificationStream.add(response.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  // Request permissions for Android 13+ and exact alarms
  Future<void> requestPermissions() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  // Schedule notification for a task
  Future<void> scheduleTaskNotification(Task task) async {
    // Cannot schedule in the past
    if (task.dateTime.isBefore(DateTime.now())) return;

    // FLAG_INSISTENT (4) causes the notification sound to loop until canceled
    final Int32List additionalFlags = Int32List.fromList(<int>[4]);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: task.id.hashCode,
      title: '⏰ Báo thức công việc!',
      body: 'Đến giờ thực hiện: ${task.title}',
      scheduledDate: tz.TZDateTime.from(task.dateTime, tz.local),
      payload: task.id, // Passes task ID to the UI when app is launched
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'task_alarms_v3', // Changed channel ID again to apply new category
          'Task Alarms',
          channelDescription: 'Continuous alarms for tasks',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.call, // 'call' category forces the banner to stay longer
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          visibility: NotificationVisibility.public,
          additionalFlags: additionalFlags,
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              'dismiss_action', 
              'Xác nhận đã biết',
              cancelNotification: true, // Tells OS to dismiss when clicked
              showsUserInterface: true, // Forces app to foreground to reliably run Dart cancel code
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock, // Forces wake up
    );
  }

  // Cancel notification
  Future<void> cancelTaskNotification(String taskId) async {
    await flutterLocalNotificationsPlugin.cancel(id: taskId.hashCode);
  }

  // Schedule Daily Briefing at 7:00 AM
  Future<void> scheduleDailyBriefing() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 7, 0);
    
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
