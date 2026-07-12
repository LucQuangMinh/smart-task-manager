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

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTasks();
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
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
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
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tasks for ${DateFormat('dd/MM/yyyy').format(_selectedDay ?? _focusedDay)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _showAddTaskDialog,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
