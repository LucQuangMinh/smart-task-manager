import 'package:flutter/material.dart';
import 'screens/calendar_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();
  await notificationService.scheduleDailyBriefing();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Task Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CalendarScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
