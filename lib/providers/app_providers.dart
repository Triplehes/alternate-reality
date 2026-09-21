import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/reality_repository.dart';
import '../domain/reality.dart';
import '../services/ai_service.dart';
import '../services/notification_service.dart';
import '../services/speech_service.dart';

final preferencesProvider = FutureProvider(
  (ref) => SharedPreferences.getInstance(),
);
final repositoryProvider = Provider<RealityRepository>((ref) {
  final prefs = ref.watch(preferencesProvider).value;
  if (prefs == null) throw StateError('Storage is loading');
  return SharedPreferencesRealityRepository(prefs);
});
final aiServiceProvider = Provider<AIService>(
  (ref) => OpenAICompatibleService(),
);
final speechServiceProvider = Provider<SpeechService>(
  (ref) => DeviceSpeechService(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => LocalNotificationService(),
);
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
final modeProvider = StateProvider<RealityMode>(
  (ref) => RealityMode.pessimistic,
);
final historyProvider = FutureProvider<List<RealityEntry>>((ref) async {
  await ref.watch(preferencesProvider.future);
  return ref.watch(repositoryProvider).getHistory();
});

enum ShiftPhase { idle, listening, generating, success, error }

class ShiftState {
  const ShiftState({this.phase = ShiftPhase.idle, this.entry, this.message});
  final ShiftPhase phase;
  final RealityEntry? entry;
  final String? message;
}

class RealityController extends Notifier<ShiftState> {
  @override
  ShiftState build() => const ShiftState();
  Future<void> generate(String input, {RealityMode? mode}) async {
    final clean = input.trim();
    if (clean.isEmpty) {
      state = const ShiftState(
        phase: ShiftPhase.error,
        message: 'Give me a thought first.',
      );
      return;
    }
    state = const ShiftState(phase: ShiftPhase.generating);
    try {
      await ref.read(preferencesProvider.future);
      final selected = mode ?? ref.read(modeProvider) ?? RealityMode.pessimistic;
      final text = await ref
          .read(aiServiceProvider)
          .generateAlternateReality(clean, selected);
      final now = DateTime.now();
      final entry = RealityEntry(
        id: now.microsecondsSinceEpoch.toString(),
        originalText: clean,
        alternateText: text,
        mode: selected,
        createdAt: now,
      );
      await ref.read(repositoryProvider).saveReality(entry);
      ref.invalidate(historyProvider);
      if (ref.read(notificationsEnabledProvider)) {
        try {
          final n = ref.read(notificationServiceProvider);
          await n.initialize();
          await n.showCurrentReality(text);
        } catch (_) {}
      }
      state = ShiftState(phase: ShiftPhase.success, entry: entry);
    } catch (_) {
      state = const ShiftState(
        phase: ShiftPhase.error,
        message: "Reality couldn't shift this time. Check your connection and try again.",
      );
    }
  }

  Future<void> listen(void Function(String) onText) async {
    try {
      final speech = ref.read(speechServiceProvider);
      if (!await speech.initialize()) {
        state = const ShiftState(
          phase: ShiftPhase.error,
          message: 'Voice input is unavailable on this device.',
        );
        return;
      }
      state = const ShiftState(phase: ShiftPhase.listening);
      await speech.startListening(onText);
    } catch (_) {
      state = const ShiftState(
        phase: ShiftPhase.error,
        message: 'Microphone access was unavailable. You can still type your thought.',
      );
    }
  }

  Future<void> stopListening() async {
    await ref.read(speechServiceProvider).stopListening();
    state = const ShiftState();
  }

  void reset() => state = const ShiftState();
}

final realityControllerProvider =
    NotifierProvider<RealityController, ShiftState>(RealityController.new);
