import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/daily_motivation.dart';
import '../services/daily_motivation_service.dart';
import 'app_providers.dart';

final dailyMotivationServiceProvider = Provider<DailyMotivationService>(
  (ref) =>
      DeviceDailyMotivationService(ref.watch(localNotificationServiceProvider)),
);

class MotivationState {
  const MotivationState({
    required this.date,
    this.enabled = false,
    this.hour = 8,
    this.minute = 0,
    this.busy = false,
    this.error,
  });
  final DateTime date;
  final bool enabled, busy;
  final int hour, minute;
  final String? error;
  String get text => DailyMotivation.forDate(date);
}

class MotivationController extends Notifier<MotivationState> {
  Timer? _midnight;
  @override
  MotivationState build() {
    ref.onDispose(() => _midnight?.cancel());
    Future.microtask(_load);
    return MotivationState(date: DateTime.now(), busy: true);
  }

  void _watchMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    _midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      refresh,
    );
  }

  Future<void> _load() async {
    if (!ref.mounted) return;
    try {
      final prefs = await ref.read(preferencesProvider.future);
      if (!ref.mounted) return;
      state = MotivationState(
        date: DateTime.now(),
        enabled: prefs.getBool('daily_motivation_enabled') ?? false,
        hour: (prefs.getInt('daily_motivation_hour') ?? 8).clamp(0, 23),
        minute: (prefs.getInt('daily_motivation_minute') ?? 0).clamp(0, 59),
      );
      await refresh();
    } catch (_) {
      if (ref.mounted) {
        state = MotivationState(
          date: DateTime.now(),
          error: 'Daily notification settings could not be loaded.',
        );
      }
    }
    if (ref.mounted) _watchMidnight();
  }

  Future<void> refresh() async {
    if (state.busy) return;
    await _apply(state.enabled, state.hour, state.minute, userAction: false);
    if (ref.mounted) _watchMidnight();
  }

  Future<void> setEnabled(bool value) =>
      _apply(value, state.hour, state.minute, userAction: true);
  Future<void> setTime(int hour, int minute) =>
      _apply(state.enabled, hour, minute, userAction: true);

  Future<void> _apply(
    bool enabled,
    int hour,
    int minute, {
    required bool userAction,
  }) async {
    if (state.busy) return;
    final previous = state;
    state = MotivationState(
      date: DateTime.now(),
      enabled: previous.enabled,
      hour: previous.hour,
      minute: previous.minute,
      busy: true,
    );
    try {
      if (enabled || userAction) {
        await ref
            .read(dailyMotivationServiceProvider)
            .configure(
              enabled: enabled,
              hour: hour,
              minute: minute,
              requestPermission: enabled && userAction,
            );
      }
      if (userAction) {
        final prefs = await ref.read(preferencesProvider.future);
        await prefs.setBool('daily_motivation_enabled', enabled);
        await prefs.setInt('daily_motivation_hour', hour);
        await prefs.setInt('daily_motivation_minute', minute);
      }
      if (!ref.mounted) return;
      state = MotivationState(
        date: DateTime.now(),
        enabled: enabled,
        hour: hour,
        minute: minute,
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = MotivationState(
        date: DateTime.now(),
        enabled: previous.enabled,
        hour: previous.hour,
        minute: previous.minute,
        error: error is MotivationException ? error.message : 'Daily notifications could not be updated. Check notification permissions and try again.',
      );
    }
  }
}

final dailyMotivationProvider =
    NotifierProvider<MotivationController, MotivationState>(
      MotivationController.new,
    );
