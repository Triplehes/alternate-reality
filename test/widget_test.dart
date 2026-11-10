import 'package:alternate_reality/data/reality_repository.dart';
import 'package:alternate_reality/domain/reality.dart';
import 'package:alternate_reality/presentation/home_screen.dart';
import 'package:alternate_reality/providers/app_providers.dart';
import 'package:alternate_reality/services/ai_service.dart';
import 'package:alternate_reality/presentation/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ImmediateAIService implements AIService {
  @override
  Future<String> generateAlternateReality(
    String input,
    RealityMode mode,
  ) async => 'I will not make it';
}

class _MemoryRealityRepository implements RealityRepository {
  final entries = <RealityEntry>[];

  @override
  Future<void> clearHistory() async => entries.clear();

  @override
  Future<void> deleteReality(String id) async =>
      entries.removeWhere((entry) => entry.id == id);

  @override
  Future<RealityEntry?> getCurrentReality() async =>
      entries.isEmpty ? null : entries.first;

  @override
  Future<List<RealityEntry>> getHistory() async => List.of(entries);

  @override
  Future<void> saveReality(RealityEntry entry) async =>
      entries.insert(0, entry);
}

void main() {
  test('RealityEntry serializes and restores', () {
    final entry = RealityEntry(
      id: '1',
      originalText: 'I got the job',
      alternateText: 'Now there is something to lose.',
      mode: RealityMode.cynical,
      createdAt: DateTime.utc(2026),
    );
    final restored = RealityEntry.fromJson(entry.toJson());
    expect(restored.originalText, entry.originalText);
    expect(restored.mode, RealityMode.cynical);
    expect(restored.isCurrent, isTrue);
  });

  testWidgets('home enables alteration only after text input', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiConfigurationProvider.overrideWithValue(
            const AIConfiguration(
              baseUrl: 'https://preview.example',
              accessToken: 'test-token-with-at-least-32-characters',
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await tester.pumpAndSettle();
    final button = find.byType(PrimaryButton);
    expect(button, findsOneWidget);
    expect(tester.widget<PrimaryButton>(button).onPressed, isNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('thoughtInput')),
      'Today will be a good day.',
    );
    await tester.pump();
    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(tester.widget<PrimaryButton>(button).onPressed, isNotNull);
  });

  testWidgets('New Thought returns to a clean input screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiConfigurationProvider.overrideWithValue(
            const AIConfiguration(
              baseUrl: 'https://preview.example',
              accessToken: 'test-token-with-at-least-32-characters',
            ),
          ),
          aiServiceProvider.overrideWithValue(_ImmediateAIService()),
          repositoryProvider.overrideWithValue(_MemoryRealityRepository()),
          notificationsEnabledProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('thoughtInput')),
      'I will make it',
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('“I will not make it”'), findsOneWidget);
    await tester.tap(find.text('NEW THOUGHT'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('thoughtInput')), findsOneWidget);
    expect(find.text('“I will not make it”'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('thoughtInput')))
          .controller
          ?.text,
      isEmpty,
    );
  });
}
