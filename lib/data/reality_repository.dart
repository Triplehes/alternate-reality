import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reality.dart';

abstract interface class RealityRepository {
  Future<List<RealityEntry>> getHistory();
  Future<RealityEntry?> getCurrentReality();
  Future<void> saveReality(RealityEntry entry);
  Future<void> deleteReality(String id);
  Future<void> clearHistory();
}

class SharedPreferencesRealityRepository implements RealityRepository {
  SharedPreferencesRealityRepository(this.preferences);
  final SharedPreferences preferences;
  static const key = 'reality_history_v1';
  static const historyLimit = 500;
  Future<void> _pending = Future.value();

  Future<void> _write(Future<void> Function() work) {
    final operation = _pending.then((_) => work());
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  @override
  Future<List<RealityEntry>> getHistory() async {
    final result = <RealityEntry>[];
    for (final value in preferences.getStringList(key) ?? const <String>[]) {
      try {
        final entry = RealityEntry.fromJson(
          jsonDecode(value) as Map<String, Object?>,
        );
        if (entry.id.isNotEmpty &&
            entry.originalText.isNotEmpty &&
            entry.alternateText.isNotEmpty) {
          result.add(entry);
        }
      } catch (_) {
        /* One damaged record must not hide the rest of the history. */
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result.take(historyLimit).toList();
  }

  Future<void> _save(List<RealityEntry> entries) async {
    if (!await preferences.setStringList(
      key,
      entries.take(historyLimit).map((e) => jsonEncode(e.toJson())).toList(),
    )) {
      throw StateError('Could not save history');
    }
  }

  @override
  Future<RealityEntry?> getCurrentReality() async {
    final items = (await getHistory()).where((e) => e.isCurrent);
    return items.isEmpty ? null : items.first;
  }

  @override
  Future<void> saveReality(RealityEntry entry) => _write(() async {
    final old = await getHistory();
    await _save([
      entry,
      ...old
          .where((e) => e.id != entry.id)
          .map(
            (e) => RealityEntry(
              id: e.id,
              originalText: e.originalText,
              alternateText: e.alternateText,
              mode: e.mode,
              createdAt: e.createdAt,
              isCurrent: false,
            ),
          ),
    ]);
  });
  @override
  Future<void> deleteReality(String id) => _write(
    () async => _save((await getHistory()).where((e) => e.id != id).toList()),
  );
  @override
  Future<void> clearHistory() => _write(() async {
    if (!await preferences.remove(key)) {
      throw StateError('Could not clear history');
    }
  });
}
