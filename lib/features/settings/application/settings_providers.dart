import 'package:alternate_reality/core/storage/preferences_provider.dart';
import 'package:alternate_reality/features/perspectives/domain/reality.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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
