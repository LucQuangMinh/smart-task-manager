import 'package:flutter/material.dart';

class RoutineTask {
  final String id;
  final String title;
  final int hour;
  final int minute;
  final bool isSilent;

  RoutineTask({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.isSilent = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'hour': hour,
      'minute': minute,
      'isSilent': isSilent,
    };
  }

  factory RoutineTask.fromJson(Map<String, dynamic> json) {
    return RoutineTask(
      id: json['id'],
      title: json['title'],
      hour: json['hour'],
      minute: json['minute'],
      isSilent: json['isSilent'] ?? false,
    );
  }
}

class Routine {
  final String id;
  final String name;
  final List<RoutineTask> tasks;

  Routine({
    required this.id,
    required this.name,
    required this.tasks,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
  }

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'],
      name: json['name'],
      tasks: (json['tasks'] as List)
          .map((t) => RoutineTask.fromJson(t))
          .toList(),
    );
  }
}
