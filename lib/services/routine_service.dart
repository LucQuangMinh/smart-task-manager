import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine.dart';

class RoutineService {
  static const String _key = 'routines_data';

  Future<List<Routine>> getRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => Routine.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveRoutines(List<Routine> routines) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = jsonEncode(routines.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }
}
