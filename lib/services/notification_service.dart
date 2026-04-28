import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models.dart';

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

  static Future<void> showReminderNotifications({
    required List<MaintenanceReminder> reminders,
    required List<Vehicle> vehicles,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'smartcar_channel',
      'Smart Car Notifications',
      channelDescription: 'Car expenses and maintenance reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    for (var i = 0; i < reminders.length; i++) {
      final reminder = reminders[i];
      Vehicle? vehicle;
      for (final candidate in vehicles) {
        if (candidate.id == reminder.vehicleId) {
          vehicle = candidate;
          break;
        }
      }
      final vehicleName = vehicle?.displayName ?? 'Vehicle';

      await _plugin.show(
        100 + i,
        '$vehicleName: ${reminder.title}',
        _buildReminderBody(reminder, vehicle),
        details,
      );
    }
  }

  static String _buildReminderBody(
    MaintenanceReminder reminder,
    Vehicle? vehicle,
  ) {
    if (reminder.dueMileage != null) {
      final unit = distanceUnitShortLabel(vehicle?.distanceUnit ?? DistanceUnit.km);
      return 'Due at ${reminder.dueMileage} $unit.';
    }
    if (reminder.dueDate != null) {
      final date = reminder.dueDate!;
      final formatted =
          '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year}';
      return 'Due on $formatted.';
    }
    return reminder.description.isEmpty
        ? 'Reminder generated from imported data.'
        : reminder.description;
  }
}

