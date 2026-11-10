import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/reality_repository.dart';
import 'access_provider.dart';
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
final aiConfigurationProvider = Provider((ref) {
  const builtIn = AIConfiguration();
  final invitation = ref.watch(accessProvider).value ?? '';
  return AIConfiguration(
    baseUrl: builtIn.baseUrl,
    accessToken: invitation.isEmpty ? builtIn.accessToken : invitation,
  );
});
final aiServiceProvider = Provider<AIService>((ref) {
  final service = BackendAIService(
    configuration: ref.watch(aiConfigurationProvider),
  );
  ref.onDispose(service.close);
  return service;
});
final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = DeviceSpeechService(
    onFinished: () {
      if (ref.mounted) {
        ref.read(realityControllerProvider.notifier).speechFinished();
      }
    },
  );
  ref.onDispose(() {
    service.cancelListening();
  });
  return service;
});
final localNotificationServiceProvider = Provider(
  (ref) => LocalNotificationService(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => ref.watch(localNotificationServiceProvider),
);
final notificationsEnabledProvider = StateProvider<bool>(
  (ref) =>
      ref
          .watch(preferencesProvider)
          .value
          ?.getBool('current_notification_enabled') ??
      true,
);
final modeProvider = StateProvider<RealityMode>((ref) {
  final saved = ref
      .watch(preferencesProvider)
      .value
      ?.getString('selected_mode');
  return RealityMode.values.firstWhere(
    (mode) => mode.name == saved,
    orElse: () => RealityMode.positive,
  );
});

Future<void> selectMode(WidgetRef ref, RealityMode mode) async {
  final previous = ref.read(modeProvider);
  ref.read(modeProvider.notifier).state = mode;
  try {
    final prefs = await ref.read(preferencesProvider.future);
    if (!await prefs.setString('selected_mode', mode.name)) {
      throw StateError('Storage failed');
    }
  } catch (_) {
    ref.read(modeProvider.notifier).state = previous;
    rethrow;
  }
}

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
  int _generation = 0;
  @override
  ShiftState build() => const ShiftState();
  Future<void> generate(String input, {RealityMode? mode}) async {
    if (state.phase == ShiftPhase.generating ||
        state.phase == ShiftPhase.listening) {
      return;
    }
    final clean = input.trim();
    if (clean.isEmpty || clean.length > 600) {
      state = const ShiftState(
        phase: ShiftPhase.error,
        message: 'Enter a thought between 1 and 600 characters.',
      );
      return;
    }
    final generation = ++_generation;
    final previous = state.entry;
    state = ShiftState(phase: ShiftPhase.generating, entry: previous);
    try {
      await ref.read(preferencesProvider.future);
      final selected =
          mode ?? ref.read(modeProvider) ?? RealityMode.pessimistic;
      final text = await ref
          .read(aiServiceProvider)
          .generateAlternateReality(clean, selected);
      if (!ref.mounted || generation != _generation) return;
      final now = DateTime.now();
      final entry = RealityEntry(
        id: now.microsecondsSinceEpoch.toString(),
        originalText: clean,
        alternateText: text,
        mode: selected,
        createdAt: now,
      );
      await ref.read(repositoryProvider).saveReality(entry);
      if (!ref.mounted || generation != _generation) return;
      ref.invalidate(historyProvider);
      if (ref.read(notificationsEnabledProvider)) {
        try {
          final n = ref.read(notificationServiceProvider);
          await n.initialize();
          await n.showCurrentReality(text);
        } catch (_) {}
      }
      if (!ref.mounted || generation != _generation) return;
      state = ShiftState(phase: ShiftPhase.success, entry: entry);
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = ShiftState(
        phase: ShiftPhase.error,
        entry: previous,
        message: error is AIServiceException
            ? error.message
            : "Reality couldn't be saved this time. Please try again.",
      );
    }
  }

  Future<void> listen(void Function(String) onText) async {
    if (state.phase == ShiftPhase.generating ||
        state.phase == ShiftPhase.listening) {
      return;
    }
    state = const ShiftState(phase: ShiftPhase.listening);
    try {
      final speech = ref.read(speechServiceProvider);
      final available = await speech.initialize();
      if (!ref.mounted) return;
      if (!available) {
        state = const ShiftState(
          phase: ShiftPhase.error,
          message: 'Voice input is unavailable on this device.',
        );
        return;
      }
      if (!ref.mounted || state.phase != ShiftPhase.listening) return;
      await speech.startListening((value) {
        if (ref.mounted && state.phase == ShiftPhase.listening) onText(value);
      });
    } catch (_) {
      if (!ref.mounted) return;
      state = const ShiftState(
        phase: ShiftPhase.error,
        message: 'Microphone access was unavailable. You can still type your thought.',
      );
    }
  }

  Future<void> stopListening() async {
    try {
      await ref.read(speechServiceProvider).stopListening();
    } catch (_) {
      if (ref.mounted) {
        state = const ShiftState(
          phase: ShiftPhase.error,
          message: 'Voice input stopped. You can still type your thought.',
        );
      }
    } finally {
      if (ref.mounted && state.phase == ShiftPhase.listening) {
        state = const ShiftState();
      }
    }
  }

  void speechFinished() {
    if (state.phase == ShiftPhase.listening) state = const ShiftState();
  }

  void reset() {
    _generation++;
    state = const ShiftState();
  }
}

final realityControllerProvider =
    NotifierProvider<RealityController, ShiftState>(RealityController.new);
