import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract interface class NotificationService {
  Future<void> initialize();
  Future<void> showCurrentReality(String text);
  Future<void> cancelCurrentReality();
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin plugin;
  static const id = 4107;
  @override
  Future<void> initialize() async {
    if (kIsWeb) return;
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(
          defaultActionName: 'Open Alternate Reality',
        ),
      ),
    );
  }

  @override
  Future<void> showCurrentReality(String text) async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    await plugin.show(
      id,
      'ALTERNATE REALITY',
      text,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'current_reality',
          'Current reality',
          channelDescription: 'The active alternate reality',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> cancelCurrentReality() =>
      kIsWeb ? Future.value() : plugin.cancel(id);
}
