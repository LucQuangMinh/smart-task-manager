import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/task.dart';

class TaskDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Task? existingTask;
  final List<Task> existingTasks;

  const TaskDialog({
    super.key,
    required this.selectedDate,
    this.existingTask,
    required this.existingTasks,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay? _selectedTime;
  bool _isTitleEmpty = true;
  bool _isSilent = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      _titleController.text = widget.existingTask!.title;
      _selectedTime = TimeOfDay.fromDateTime(widget.existingTask!.dateTime);
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

  bool get _isPastTime {
    if (_selectedTime == null) return false;
    final taskDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Nếu đang sửa và không đổi giờ thì cho phép lưu
    if (widget.existingTask != null) {
      final oldTime = TimeOfDay.fromDateTime(widget.existingTask!.dateTime);
      if (oldTime.hour == _selectedTime!.hour &&
          oldTime.minute == _selectedTime!.minute) {
        return false;
      }
    }

    return taskDateTime.isBefore(DateTime.now());
  }

  bool get _isTimeCollision {
    if (_selectedTime == null) return false;
    for (var task in widget.existingTasks) {
      if (widget.existingTask != null && task.id == widget.existingTask!.id) {
        continue; // Bỏ qua task đang sửa
      }
      if (task.dateTime.year == widget.selectedDate.year &&
          task.dateTime.month == widget.selectedDate.month &&
          task.dateTime.day == widget.selectedDate.day &&
          task.dateTime.hour == _selectedTime!.hour &&
          task.dateTime.minute == _selectedTime!.minute) {
        return true;
      }
    }
    return false;
  }

  void _pickTime() {
    final now = DateTime.now();
    final initialDateTime = _selectedTime == null
        ? now
        : DateTime(now.year, now.month, now.day, _selectedTime!.hour,
            _selectedTime!.minute);

    TimeOfDay tempTime = _selectedTime ?? TimeOfDay.now();

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
                  child: Text('Hủy',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: Text('Xong',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
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
                initialDateTime: initialDateTime,
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
    if (_isTitleEmpty || _selectedTime == null || _isPastTime || _isTimeCollision) {
      return;
    }

    final title = _titleController.text.trim();
    final taskDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final newTask = Task(
      id: widget.existingTask?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      dateTime: taskDateTime,
      isCompleted: widget.existingTask?.isCompleted ?? false,
      isSilent: _isSilent,
    );

    Navigator.of(context).pop(newTask);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTask != null;
    final isPastTask = isEditing && widget.existingTask!.dateTime.isBefore(DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Cập Nhật Công Việc' : 'Thêm Công Việc Mới',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              autofocus: !isEditing,
              decoration: InputDecoration(
                labelText: 'Tên công việc',
                hintText: 'VD: Họp team dự án...',
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.task_alt),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: isPastTask ? null : _pickTime,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: isPastTask ? Colors.grey.shade300 : Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                  color: isPastTask ? Colors.grey.shade100 : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(isPastTask ? Icons.lock_clock : Icons.access_time_filled,
                        color: isPastTask ? Colors.grey : Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _selectedTime == null
                            ? 'Chưa chọn giờ'
                            : 'Thời gian: ${_selectedTime!.format(context)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedTime == null
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: isPastTask ? Colors.grey : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (!isPastTask) const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            if (_selectedTime == null)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text('Vui lòng chọn thời gian!',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              )
            else if (_isPastTime)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text('Không thể chọn thời gian trong quá khứ!',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              )
            else if (_isTimeCollision)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text('Khung giờ này đã bị trùng với Task khác!',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<bool>(
                groupValue: _isSilent,
                children: const {
                  false: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('🔔 Có chuông', style: TextStyle(fontSize: 14)),
                  ),
                  true: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('🔕 Im lặng', style: TextStyle(fontSize: 14)),
                  ),
                },
                onValueChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _isSilent = value;
                    });
                  }
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Hủy',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isTitleEmpty ||
                            _selectedTime == null ||
                            _isPastTime ||
                            _isTimeCollision)
                        ? null
                        : _saveTask,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(isEditing ? 'Cập Nhật' : 'Lưu Task',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
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
