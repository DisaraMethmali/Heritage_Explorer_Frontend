// /frontend/lib/main.dart (app entry)

import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'services/location_monitor.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification system (services)
  await NotificationService.init();

  // Start global location monitor
  LocationMonitor.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Heritage Explorer',
      home: SplashScreen(),
    );
  }
}
