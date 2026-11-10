import 'package:alternate_reality/domain/daily_motivation.dart';
import 'package:alternate_reality/providers/app_providers.dart';
import 'package:alternate_reality/providers/motivation_provider.dart';
import 'package:alternate_reality/services/daily_motivation_service.dart';
import 'package:alternate_reality/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeDaily implements DailyMotivationService {
  final calls = <(bool, int, int, bool)>[];
  bool fail = false;
  @override
  bool get supported => true;
  @override
  Future<void> configure({
    required bool enabled,
    required int hour,
    required int minute,
    required bool requestPermission,
  }) async {
    calls.add((enabled, hour, minute, requestPermission));
    if (fail) throw const MotivationException('Permission denied');
  }
}

Future<void> loaded(ProviderContainer container) async {
  container.read(dailyMotivationProvider);
  await container.read(preferencesProvider.future);
  for (var i = 0; i < 10 && container.read(dailyMotivationProvider).busy; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class TestNotifications extends LocalNotificationService {
  TestNotifications({super.plugin});
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('60 unique texts are stable within a date and change at midnight', () {
    expect(DailyMotivation.messages.length, 60);
    expect(DailyMotivation.messages.toSet().length, 60);
    expect(
      DailyMotivation.forDate(DateTime(2026, 11, 9, 0)),
      DailyMotivation.forDate(DateTime(2026, 11, 9, 23, 59)),
    );
    for (var i = 0; i < 370; i++) {
      expect(
        DailyMotivation.forDate(DateTime(2026, 1, 1 + i)),
        isNot(DailyMotivation.forDate(DateTime(2026, 1, 2 + i))),
      );
    }
    expect(DailyMotivation.dayIndex(DateTime(1970, 1, 1)), 0);
  });
  test('queue crosses month/year/leap-day boundaries at local 8 AM', () {
    for (final now in [
      DateTime(2026, 12, 31, 9),
      DateTime(2028, 2, 28, 9),
      DateTime(2026, 11, 9, 8),
    ]) {
      final dates = DailyMotivation.upcoming(now, 8, 0);
      expect(dates.length, 30);
      expect(dates.first.isAfter(now), isTrue);
      expect(dates.first.day, DateTime(now.year, now.month, now.day + 1).day);
      expect(dates.every((d) => d.hour == 8 && d.minute == 0), isTrue);
      expect(dates.toSet().length, 30);
    }
    expect(
      DailyMotivation.upcoming(DateTime(2026, 11, 9, 7), 8, 0).first,
      DateTime(2026, 11, 9, 8),
    );
  });
  test('enabling, changing time and disabling persists independently of current reality', () async {
    final service = FakeDaily();
    final container = ProviderContainer(
      overrides: [dailyMotivationServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    await loaded(container);
    expect(container.read(dailyMotivationProvider).hour, 8);
    expect(container.read(dailyMotivationProvider).enabled, isFalse);
    expect(service.calls, isEmpty);
    final current = container.read(notificationsEnabledProvider);
    final controller = container.read(dailyMotivationProvider.notifier);
    await controller.setEnabled(true);
    await controller.setTime(9, 15);
    expect(service.calls.last, (true, 9, 15, true));
    await controller.setEnabled(false);
    expect(service.calls.last, (false, 9, 15, false));
    expect(container.read(notificationsEnabledProvider), current);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('daily_motivation_enabled'), isFalse);
    expect(prefs.getInt('daily_motivation_hour'), 9);
    expect(prefs.getInt('daily_motivation_minute'), 15);
  });
  test(
    'saved schedule is restored without requesting permissions on startup',
    () async {
      SharedPreferences.setMockInitialValues({
        'daily_motivation_enabled': true,
        'daily_motivation_hour': 8,
        'daily_motivation_minute': 0,
      });
      final service = FakeDaily();
      final container = ProviderContainer(
        overrides: [dailyMotivationServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      await loaded(container);
      expect(service.calls.single, (true, 8, 0, false));
    },
  );
  test(
    'permission/scheduling failure is visible and does not enable the setting',
    () async {
      final service = FakeDaily()..fail = true;
      final container = ProviderContainer(
        overrides: [dailyMotivationServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      await loaded(container);
      await container.read(dailyMotivationProvider.notifier).setEnabled(true);
      expect(container.read(dailyMotivationProvider).enabled, isFalse);
      expect(
        container.read(dailyMotivationProvider).error,
        'Permission denied',
      );
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'daily_motivation_enabled',
        ),
        isNull,
      );
    },
  );
  test(
    'Android native bridge receives one schedule and the same quote catalog',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel('alternate_reality/daily_motivation');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final service = DeviceDailyMotivationService(TestNotifications());
      await service.configure(
        enabled: true,
        hour: 8,
        minute: 0,
        requestPermission: true,
      );
      expect(calls.single.arguments['messages'], DailyMotivation.messages);
      expect(calls.single.arguments['hour'], 8);
      expect(calls.single.arguments['enabled'], isTrue);
      await service.configure(
        enabled: false,
        hour: 8,
        minute: 0,
        requestPermission: false,
      );
      expect(calls.last.arguments['enabled'], isFalse);
      expect(
        DeviceDailyMotivationService.notificationId,
        isNot(LocalNotificationService.id),
      );
    },
  );
  test('Darwin schedules 30 different daily texts and never cancels current reality', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final current = DateTime.now();
    final futureDay = DateTime(current.year, current.month, current.day + 2, 9);
    final service = DeviceDailyMotivationService(
      TestNotifications(plugin: FlutterLocalNotificationsPlugin()),
      now: () => futureDay,
    );
    await service.configure(
      enabled: true,
      hour: 8,
      minute: 0,
      requestPermission: false,
    );
    final scheduled = calls.where((c) => c.method == 'zonedSchedule').toList();
    expect(scheduled.length, 30);
    expect(scheduled.map((c) => c.arguments['body']).toSet().length, 30);
    expect(
      scheduled.first.arguments['body'],
      DailyMotivation.forDate(
        DateTime(futureDay.year, futureDay.month, futureDay.day + 1),
      ),
    );
    await service.configure(
      enabled: false,
      hour: 8,
      minute: 0,
      requestPermission: false,
    );
    expect(
      calls
          .where((c) => c.method == 'cancel')
          .any((c) => c.arguments == LocalNotificationService.id),
      isFalse,
    );
    expect(calls.any((c) => c.method == 'cancelAll'), isFalse);
  });
}
