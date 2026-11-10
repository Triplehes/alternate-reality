import 'package:alternate_reality/core/storage/preferences_provider.dart';
import 'package:alternate_reality/features/history/data/reality_repository.dart';
import 'package:alternate_reality/features/perspectives/domain/reality.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final repositoryProvider = Provider<RealityRepository>((ref) {
  final prefs = ref.watch(preferencesProvider).value;
  if (prefs == null) throw StateError('Storage is loading');
  return SharedPreferencesRealityRepository(prefs);
});
final historyProvider = FutureProvider<List<RealityEntry>>((ref) async {
  await ref.watch(preferencesProvider.future);
  return ref.watch(repositoryProvider).getHistory();
});
