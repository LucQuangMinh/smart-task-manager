import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/routine_service.dart';
import 'routine_detail_screen.dart';

class RoutineListScreen extends StatefulWidget {
  const RoutineListScreen({super.key});

  @override
  State<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  final RoutineService _routineService = RoutineService();
  List<Routine> _routines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final routines = await _routineService.getRoutines();
    setState(() {
      _routines = routines;
      _isLoading = false;
    });
  }

  Future<void> _saveRoutines() async {
    await _routineService.saveRoutines(_routines);
  }

  void _addRoutine() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Lịch trình mới'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Tên lịch trình (VD: Buổi sáng)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _routines.add(Routine(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    tasks: [],
                  ));
                });
                _saveRoutines();
                Navigator.pop(context);
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _deleteRoutine(String id) {
    setState(() {
      _routines.removeWhere((r) => r.id == id);
    });
    _saveRoutines();
  }

  void _editRoutine(Routine routine) async {
    final controller = TextEditingController(text: routine.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa Tên Lịch trình'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Tên lịch trình'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        final index = _routines.indexWhere((r) => r.id == routine.id);
        if (index != -1) {
          _routines[index] = Routine(id: routine.id, name: newName, tasks: routine.tasks);
        }
      });
      _saveRoutines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Lịch trình mẫu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routines.isEmpty
              ? const Center(child: Text('Chưa có Lịch trình nào.\nBấm + để tạo nhé!', textAlign: TextAlign.center))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _routines.length,
                  itemBuilder: (context, index) {
                    final routine = _routines[index];
                    return Dismissible(
                      key: Key(routine.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red.shade400,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteRoutine(routine.id),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(routine.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${routine.tasks.length} công việc'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editRoutine(routine),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RoutineDetailScreen(
                                  routine: routine,
                                  onRoutineUpdated: (updatedRoutine) {
                                    setState(() {
                                      final i = _routines.indexWhere((r) => r.id == updatedRoutine.id);
                                      if (i != -1) _routines[i] = updatedRoutine;
                                    });
                                    _saveRoutines();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRoutine,
        child: const Icon(Icons.add),
      ),
    );
  }
}
