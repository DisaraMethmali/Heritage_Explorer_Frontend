// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'services/voice_service.dart';
import 'services/notification_service.dart';
import 'services/location_monitor.dart';

import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification system
  await NotificationService.init();

  // Start global location monitor
  LocationMonitor.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, auth, chat) {
            chat!.setUserId(auth.user?.userId);
            return chat;
          },
        ),
        // VoiceService registered at root
        ChangeNotifierProvider(create: (_) => VoiceService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Heritage Explorer',
        home: SplashScreen(),
      ),
    );
  }
}