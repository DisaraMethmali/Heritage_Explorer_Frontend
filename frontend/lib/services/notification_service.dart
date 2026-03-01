// frontend/lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/notification_navigation.dart'; // Handles notification tap navigation

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notification service
  static Future<void> init() async {
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: android);

    // Handle notification tap here
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == "recommendation") {
          NotificationNavigation.handleRecommendationTap();
        }
      },
    );

    // REQUEST PERMISSION (Android 13+)
    await _requestPermission();
  }

  // Request notification permission
  static Future<void> _requestPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  // Show nearby heritage notification
  static Future<void> showNearbyNotification(
      String title, String body) async {

    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'nearby_channel',
      'Nearby Heritage Alerts',
      channelDescription: 'Notifications when you approach a heritage site',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platform = NotificationDetails(android: android);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      title,
      body,
      platform,
      payload: "recommendation", // used for deep-link navigation
    );
  }
}
