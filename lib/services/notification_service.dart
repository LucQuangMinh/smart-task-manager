import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:shared_preferences/shared_preferences.dart';
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
    if (task.isSilent) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: task.id.hashCode,
        title: 'Nhắc nhở: ${task.title}',
        body: 'Đến giờ thực hiện công việc của bạn rồi!',
        scheduledDate: tz.TZDateTime.from(task.dateTime, tz.local),
        payload: task.id,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_silent_v2', // Cập nhật ID mới để Android nhận cấu hình mới
            'Task Silent Reminders',
            channelDescription: 'Quiet reminders for tasks',
            importance: Importance.high, // Thay đổi từ low -> high để có Banner trượt xuống
            priority: Priority.high,
            playSound: false, // Vẫn giữ im lặng
            enableVibration: false, // Không rung
            fullScreenIntent: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } else {
      // FLAG_INSISTENT (4) causes the notification sound to loop until canceled
      final Int32List additionalFlags = Int32List.fromList(<int>[4]);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: task.id.hashCode,
        title: '⏰ Báo thức công việc!',
        body: 'Đến giờ thực hiện: ${task.title}',
        scheduledDate: tz.TZDateTime.from(task.dateTime, tz.local),
        payload: task.id,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'task_alarms_v3',
            'Task Alarms',
            channelDescription: 'Continuous alarms for tasks',
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.call,
            fullScreenIntent: true,
            ongoing: true,
            autoCancel: false,
            visibility: NotificationVisibility.public,
            additionalFlags: additionalFlags,
            actions: const <AndroidNotificationAction>[
              AndroidNotificationAction(
                'dismiss_action',
                'Xác nhận đã biết',
                cancelNotification: true,
                showsUserInterface: true,
              ),
            ],
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
    }
  }

  // Cancel notification for a task
  Future<void> cancelTaskNotification(String taskId) async {
    await flutterLocalNotificationsPlugin.cancel(id: taskId.hashCode);
  }

  // Methods for Briefing Settings
  Future<TimeOfDay> getBriefingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('briefing_hour') ?? 7;
    final minute = prefs.getInt('briefing_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> saveBriefingTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('briefing_hour', time.hour);
    await prefs.setInt('briefing_minute', time.minute);
  }

  // Schedule summary notification at 7:00 AM (or user configured time) every day
  Future<void> scheduleMorningBriefings(List<Task> allUncompletedTasks) async {
    final now = DateTime.now();
    final briefingTime = await getBriefingTime();

    // Group tasks by day
    final Map<DateTime, List<Task>> tasksByDate = {};
    for (var task in allUncompletedTasks) {
      final date = DateTime(task.dateTime.year, task.dateTime.month, task.dateTime.day);
      tasksByDate.putIfAbsent(date, () => []).add(task);
    }

    // Process from today up to next 30 days
    for (int i = 0; i < 30; i++) {
      final targetDate = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      final notificationId = targetDate.year * 10000 + targetDate.month * 100 + targetDate.day;

      final tasksForDay = tasksByDate[targetDate] ?? [];
      final scheduleTime = DateTime(targetDate.year, targetDate.month, targetDate.day, briefingTime.hour, briefingTime.minute);

      // Cancel if no tasks or if time is already passed for that day
      if (tasksForDay.isEmpty || scheduleTime.isBefore(now)) {
        await flutterLocalNotificationsPlugin.cancel(id: notificationId);
        continue;
      }

      final title = 'Chào buổi sáng! 🌅';
      final body = 'Hôm nay bạn có ${tasksForDay.length} công việc: ${tasksForDay.map((e) => e.title).take(3).join(', ')}${tasksForDay.length > 3 ? '...' : ''}';

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduleTime, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'morning_briefing_channel',
            'Morning Briefing',
            channelDescription: 'Daily silent summary at 7:00 AM',
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

}
