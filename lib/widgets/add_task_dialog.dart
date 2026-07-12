import 'package:flutter/material.dart';
import '../models/task.dart';

class AddTaskDialog extends StatefulWidget {
  final DateTime selectedDate;

  const AddTaskDialog({super.key, required this.selectedDate});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay? _selectedTime;
  bool _isTitleEmpty = true;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      setState(() {
        _isTitleEmpty = _titleController.text.trim().isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _saveTask() {
    if (_isTitleEmpty || _selectedTime == null) return;

    final title = _titleController.text.trim();
    // 1. Combine selectedDate with selectedTime
    final taskDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // basic unique id
      title: title,
      dateTime: taskDateTime,
    );

    Navigator.of(context).pop(newTask);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true, // 3. Autofocus to open keyboard automatically
            decoration: const InputDecoration(
              labelText: 'Task Title',
              hintText: 'e.g., Learn Flutter',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedTime == null
                      ? 'No time selected'
                      : 'Time: ${_selectedTime!.format(context)}',
                ),
              ),
              OutlinedButton(
                onPressed: _pickTime,
                child: const Text('Pick Time'),
              ),
            ],
          ),
          // 2. Validation UI
          if (_selectedTime == null)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Please select a time',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          // 2. Disable save button if validation fails
          onPressed: (_isTitleEmpty || _selectedTime == null)
              ? null
              : _saveTask,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
