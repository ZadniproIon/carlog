import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    // Android 13+ runtime permission
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
  }

  static Future<void> showDemoNotifications(BuildContext context) async {
    const androidDetails = AndroidNotificationDetails(
      'smartcar_channel',
      'Smart Car Notifications',
      channelDescription: 'Car expenses and maintenance reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    final messages = <({int id, String title, String body})>[
      (
        id: 1,
        title: 'Passat: oil change coming up',
        body: 'Oil change due in 1 200 km.',
      ),
      (
        id: 2,
        title: 'Model 3: tire rotation',
        body: 'Tire rotation recommended at 26 000 km.',
      ),
      (
        id: 3,
        title: 'Cayenne: hybrid system check',
        body: 'Hybrid system check scheduled in 7 days.',
      ),
    ];

    for (final m in messages) {
      await _plugin.show(m.id, m.title, m.body, details);
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sent 3 demo notifications to the system tray.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

