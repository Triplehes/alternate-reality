import 'package:alternate_reality/features/notifications/data/local_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localNotificationServiceProvider = Provider(
  (ref) => LocalNotificationService(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => ref.watch(localNotificationServiceProvider),
);
