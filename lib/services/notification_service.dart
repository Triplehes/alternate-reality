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
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
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
    _initialized = true;
  }

  @override
  Future<void> showCurrentReality(String text) async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      final allowed = await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      if (allowed == false) return;
    } else if (Platform.isIOS) {
      final allowed = await plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      if (allowed == false) return;
    } else if (Platform.isMacOS) {
      final allowed = await plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      if (allowed == false) return;
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
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
        ),
        linux: LinuxNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> cancelCurrentReality() =>
      kIsWeb ? Future.value() : plugin.cancel(id);
}
