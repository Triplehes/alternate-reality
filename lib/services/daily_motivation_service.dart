import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/daily_motivation.dart';
import 'notification_service.dart';

abstract interface class DailyMotivationService {
  bool get supported;
  Future<void> configure({
    required bool enabled,
    required int hour,
    required int minute,
    required bool requestPermission,
  });
}

class DeviceDailyMotivationService implements DailyMotivationService {
  DeviceDailyMotivationService(
    this.notifications, {
    MethodChannel? channel,
    DateTime Function()? now,
  }) : channel =
           channel ?? const MethodChannel('alternate_reality/daily_motivation'),
       now = now ?? DateTime.now;
  final LocalNotificationService notifications;
  final MethodChannel channel;
  final DateTime Function() now;
  static const notificationId = 4108;
  static const firstScheduledId = 4200;
  static const scheduledCount = 30;

  @override
  bool get supported =>
      !kIsWeb &&
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform);

  static const details = NotificationDetails(
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
      threadIdentifier: 'daily_motivation',
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
      threadIdentifier: 'daily_motivation',
    ),
  );

  @override
  Future<void> configure({
    required bool enabled,
    required int hour,
    required int minute,
    required bool requestPermission,
  }) async {
    if (!supported) {
      if (enabled) {
        throw const MotivationException(
          'Daily notifications are supported on Android, iOS and macOS.',
        );
      }
      return;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw const MotivationException('Choose a valid notification time.');
    }
    await notifications.initialize();
    if (enabled &&
        requestPermission &&
        !await notifications.requestPermission()) {
      throw const MotivationException(
        'Notifications are blocked. Allow them in your device settings, then try again.',
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await channel.invokeMethod<void>('configure', {
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
        'messages': DailyMotivation.messages,
        'showToday': requestPermission,
      });
      return;
    }
    // Darwin queues have a finite capacity. Only our IDs are removed; 4107 is untouched.
    for (var i = 0; i < scheduledCount; i++) {
      await notifications.plugin.cancel(firstScheduledId + i);
    }
    if (!enabled) {
      await notifications.plugin.cancel(notificationId);
      return;
    }
    final today = now();
    final dates = DailyMotivation.upcoming(
      today,
      hour,
      minute,
      count: scheduledCount,
    );
    try {
      for (var i = 0; i < dates.length; i++) {
        await notifications.plugin.zonedSchedule(
          firstScheduledId + i,
          'DAILY MOTIVATION',
          DailyMotivation.forDate(dates[i]),
          tz.TZDateTime.from(dates[i], tz.UTC),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      // Refresh today's visible item silently when reopening; enabling previews it immediately.
      await notifications.plugin.show(
        notificationId,
        'DAILY MOTIVATION',
        DailyMotivation.forDate(today),
        NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: requestPermission,
            presentBanner: requestPermission,
            presentList: true,
            presentSound: requestPermission,
            threadIdentifier: 'daily_motivation',
          ),
          macOS: DarwinNotificationDetails(
            presentAlert: requestPermission,
            presentBanner: requestPermission,
            presentList: true,
            presentSound: requestPermission,
            threadIdentifier: 'daily_motivation',
          ),
        ),
      );
    } catch (_) {
      for (var i = 0; i < scheduledCount; i++) {
        await notifications.plugin.cancel(firstScheduledId + i);
      }
      rethrow;
    }
  }
}

class MotivationException implements Exception {
  const MotivationException(this.message);
  final String message;
}
