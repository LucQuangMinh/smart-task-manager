import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../widgets/add_routine_task_dialog.dart';

class RoutineDetailScreen extends StatefulWidget {
  final Routine routine;
  final ValueChanged<Routine> onRoutineUpdated;

  const RoutineDetailScreen({
    super.key,
    required this.routine,
    required this.onRoutineUpdated,
  });

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  late Routine _routine;

  @override
  void initState() {
    super.initState();
    _routine = widget.routine;
  }

  void _showTaskDialog({RoutineTask? existingTask}) async {
    final newTask = await showDialog<RoutineTask>(
      context: context,
      builder: (context) => AddRoutineTaskDialog(existingTask: existingTask),
    );

    if (newTask != null) {
      setState(() {
        if (existingTask != null) {
          final index = _routine.tasks.indexWhere((t) => t.id == existingTask.id);
          if (index != -1) {
            _routine.tasks[index] = newTask;
          }
        } else {
          _routine.tasks.add(newTask);
        }
        // Sort by time
        _routine.tasks.sort((a, b) {
          if (a.hour != b.hour) return a.hour.compareTo(b.hour);
          return a.minute.compareTo(b.minute);
        });
      });
      widget.onRoutineUpdated(_routine);
    }
  }

  void _deleteTask(String id) {
    setState(() {
      _routine.tasks.removeWhere((t) => t.id == id);
    });
    widget.onRoutineUpdated(_routine);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_routine.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _routine.tasks.isEmpty
          ? const Center(child: Text('Chưa có công việc nào trong Lịch trình này. 🚀\nBấm + để thêm!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _routine.tasks.length,
              itemBuilder: (context, index) {
                final task = _routine.tasks[index];
                final timeString = '${task.hour.toString().padLeft(2, '0')}:${task.minute.toString().padLeft(2, '0')}';
                
                return Dismissible(
                  key: Key(task.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_sweep, color: Colors.white, size: 32),
                  ),
                  onDismissed: (_) => _deleteTask(task.id),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.access_time, size: 14),
                          const SizedBox(width: 4),
                          Text(timeString),
                          const SizedBox(width: 8),
                          Icon(
                            task.isSilent ? Icons.notifications_off_outlined : Icons.notifications_active_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_note),
                        onPressed: () => _showTaskDialog(existingTask: task),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
