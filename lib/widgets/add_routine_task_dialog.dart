import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/routine.dart';

class AddRoutineTaskDialog extends StatefulWidget {
  final RoutineTask? existingTask;

  const AddRoutineTaskDialog({super.key, this.existingTask});

  @override
  State<AddRoutineTaskDialog> createState() => _AddRoutineTaskDialogState();
}

class _AddRoutineTaskDialogState extends State<AddRoutineTaskDialog> {
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay? _selectedTime;
  bool _isTitleEmpty = true;
  bool _isSilent = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      _titleController.text = widget.existingTask!.title;
      _selectedTime = TimeOfDay(
        hour: widget.existingTask!.hour,
        minute: widget.existingTask!.minute,
      );
      _isSilent = widget.existingTask!.isSilent;
      _isTitleEmpty = false;
    }
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

  void _pickTime() {
    TimeOfDay tempTime = _selectedTime ?? const TimeOfDay(hour: 8, minute: 0);
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text('Hủy', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: Text('Xong', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  onPressed: () {
                    setState(() {
                      _selectedTime = tempTime;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(2024, 1, 1, tempTime.hour, tempTime.minute),
                onDateTimeChanged: (DateTime val) {
                  tempTime = TimeOfDay(hour: val.hour, minute: val.minute);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTask() {
    if (_isTitleEmpty || _selectedTime == null) return;

    final newTask = RoutineTask(
      id: widget.existingTask?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      hour: _selectedTime!.hour,
      minute: _selectedTime!.minute,
      isSilent: _isSilent,
    );

    Navigator.of(context).pop(newTask);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTask != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Sửa Công Việc Mẫu' : 'Thêm Công Việc Mẫu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              autofocus: !isEditing,
              decoration: InputDecoration(
                labelText: 'Tên công việc',
                hintText: 'VD: Tập thể dục...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.task_alt),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_filled, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _selectedTime == null ? 'Chưa chọn giờ' : 'Thời gian: ${_selectedTime!.format(context)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedTime == null ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<bool>(
                groupValue: _isSilent,
                children: const {
                  false: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('🔔 Có chuông', style: TextStyle(fontSize: 14))),
                  true: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('🔕 Im lặng', style: TextStyle(fontSize: 14))),
                },
                onValueChanged: (value) {
                  if (value != null) setState(() => _isSilent = value);
                },
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isTitleEmpty || _selectedTime == null) ? null : _saveTask,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(isEditing ? 'Cập Nhật' : 'Lưu', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
