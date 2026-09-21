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
  @override
  Future<List<RealityEntry>> getHistory() async {
    final result = (preferences.getStringList(key) ?? const <String>[])
        .map(
          (e) => RealityEntry.fromJson(jsonDecode(e) as Map<String, Object?>),
        )
        .toList();
    return result..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<RealityEntry?> getCurrentReality() async {
    final items = (await getHistory()).where((e) => e.isCurrent);
    return items.isEmpty ? null : items.first;
  }

  @override
  Future<void> saveReality(RealityEntry entry) async {
    final old = await getHistory();
    final updated = [
      entry,
      ...old.map(
        (e) => RealityEntry(
          id: e.id,
          originalText: e.originalText,
          alternateText: e.alternateText,
          mode: e.mode,
          createdAt: e.createdAt,
          isCurrent: false,
        ),
      ),
    ];
    await preferences.setStringList(
      key,
      updated.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  @override
  Future<void> deleteReality(String id) async {
    final h = await getHistory();
    await preferences.setStringList(
      key,
      h.where((e) => e.id != id).map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  @override
  Future<void> clearHistory() => preferences.remove(key);
}
