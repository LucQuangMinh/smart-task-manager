import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?> onChanged;

  const TaskListItem({super.key, required this.task, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Container(
          width: 4,
          height: double.infinity,
          color: task.isCompleted
              ? Colors.grey
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Text(DateFormat('HH:mm').format(task.dateTime)),
        trailing: Checkbox(value: task.isCompleted, onChanged: onChanged),
      ),
    );
  }
}
