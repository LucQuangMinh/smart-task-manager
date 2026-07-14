import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/notification_service.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_list_item.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Task> _tasks = [];
  bool _isLoading = true;
  late StreamSubscription<String?> _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTasks().then((_) {
      _checkPendingNotification();
    });

    // Listen for incoming notifications when app is active (singleTop resume)
    _notificationSubscription = NotificationService().selectNotificationStream.stream.listen((String? payload) {
      if (payload != null) {
        _handleAlarmTriggered(payload);
      }
    });
  }

  // Check if the app was cold-booted via a notification tap or auto-launch
  Future<void> _checkPendingNotification() async {
    final details = await NotificationService().flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      final payload = details?.notificationResponse?.payload;
      if (payload != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleAlarmTriggered(payload);
        });
      }
    }
  }

  // The actual dialog that forces the user to dismiss
  void _handleAlarmTriggered(String taskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId, orElse: () => Task(id: '', title: 'Unknown', dateTime: DateTime.now()));
    if (task.id.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.alarm_on_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
        title: const Text('⏰ BÁO THỨC!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Đã đến giờ thực hiện nhiệm vụ:\n\n"${task.title}"', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                NotificationService().cancelTaskNotification(taskId);
                Navigator.of(context).pop();
              },
              child: const Text('XÁC NHẬN ĐÃ BIẾT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  // Load tasks from SharedPreferences
  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('tasks');

    if (tasksJson == null) {
      // Initialize mock data if storage is completely empty (first run)
      final now = DateTime.now();
      _tasks = [
        Task(
          id: '1',
          title: 'Họp team dự án',
          dateTime: DateTime(now.year, now.month, now.day, 9, 0),
        ),
        Task(
          id: '2',
          title: 'Ăn trưa với khách hàng',
          dateTime: DateTime(now.year, now.month, now.day, 12, 30),
        ),
        Task(
          id: '3',
          title: 'Viết báo cáo tuần',
          dateTime: DateTime(now.year, now.month, now.day, 16, 45),
          isCompleted: true,
        ),
        Task(
          id: '4',
          title: 'Đi siêu thị mua đồ',
          dateTime: DateTime(now.year, now.month, now.day + 1, 18, 0),
        ),
      ];
      // Save the mock data so it persists immediately
      await _saveTasks(updateState: false);
    } else {
      // Decode the JSON string to a List of Task objects
      final List<dynamic> decodedData = jsonDecode(tasksJson);
      _tasks = decodedData.map((item) => Task.fromJson(item)).toList();
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Save tasks to SharedPreferences
  Future<void> _saveTasks({bool updateState = true}) async {
    if (updateState) {
      setState(() {});
    }

    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonData = _tasks
        .map((task) => task.toJson())
        .toList();
    await prefs.setString('tasks', jsonEncode(jsonData));

    // Synchronize notifications with task state
    for (var task in _tasks) {
      if (task.isCompleted) {
        await NotificationService().cancelTaskNotification(task.id);
      } else {
        await NotificationService().scheduleTaskNotification(task);
      }
    }
  }

  // Filter tasks for a specific day
  List<Task> _getTasksForDay(DateTime day) {
    return _tasks.where((task) => isSameDay(task.dateTime, day)).toList();
  }

  void _showAddTaskDialog() async {
    final newTask = await showDialog<Task>(
      context: context,
      builder: (context) =>
          AddTaskDialog(selectedDate: _selectedDay ?? _focusedDay),
    );

    if (newTask != null) {
      _tasks.add(newTask);
      _saveTasks(); // Auto-save after adding
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào!',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Hôm nay có gì mới?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Task>(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getTasksForDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                shape: BoxShape.rectangle,
              ),
              todayTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.rectangle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();

                final completedCount = events.where((task) => task.isCompleted).length;
                final totalCount = events.length;
                final isSelected = isSameDay(date, _selectedDay);

                return Positioned(
                  bottom: 8, // Moved inside the cell margin (default is 6.0)
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white70 : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        '$totalCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 24.0, left: 20.0, right: 20.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Công việc ngày ${DateFormat('dd/MM').format(_selectedDay ?? _focusedDay)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_getTasksForDay(_selectedDay ?? _focusedDay).length} Tasks',
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final tasksForSelectedDay = _getTasksForDay(
                                _selectedDay ?? _focusedDay,
                              );

                              if (tasksForSelectedDay.isEmpty) {
                                return const Center(
                                  child: Text('No tasks for this day yet.'),
                                );
                              }

                              return ListView.builder(
                                itemCount: tasksForSelectedDay.length,
                                itemBuilder: (context, index) {
                                  final task = tasksForSelectedDay[index];
                                  return TaskListItem(
                                    task: task,
                                    onChanged: (value) {
                                      task.isCompleted = value ?? false;
                                      _saveTasks(); // Auto-save after toggling checkbox
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _showAddTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm Task', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
    );
  }
  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }
}
