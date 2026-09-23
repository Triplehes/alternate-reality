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
  ) async => LiteralNegativeEngine.transform(input);
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

  test('prompt contains safety and selected mode', () {
    final prompt = AlternateRealityPrompt.system(RealityMode.darkHumor);
    expect(prompt, contains('dark humor'));
    expect(prompt, contains('self-harm'));
    expect(prompt, contains('plain text'));
  });

  test('response validation rejects malformed output', () {
    expect(
      () => OpenAICompatibleService.validate(''),
      throwsA(isA<AIServiceException>()),
    );
    expect(
      () => OpenAICompatibleService.validate('{"debug":true}'),
      throwsA(isA<AIServiceException>()),
    );
    expect(
      OpenAICompatibleService.validate('A colder possibility.'),
      'A colder possibility.',
    );
  });

  test('fallback returns supportive text for self-harm input', () async {
    final result = await LocalFallbackAIService().generateAlternateReality(
      'I want to kill myself',
      RealityMode.pessimistic,
    );
    expect(result, contains('contact someone you trust'));
    expect(result, isNot(contains('punishment deserved')));
  });

  test('literal engine creates the direct negative opposite', () {
    expect(
      LiteralNegativeEngine.transform('I will make it'),
      'I will not make it',
    );
    expect(
      LiteralNegativeEngine.transform('I will make it, I know I will make it'),
      "I will not make it, I know I won't make it",
    );
    expect(LiteralNegativeEngine.transform('I am ready'), 'I am not ready');
  });

  testWidgets('home enables alteration only after text input', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -650));
    await tester.pumpAndSettle();
    final button = find.byType(PrimaryButton);
    expect(button, findsOneWidget);
    expect(tester.widget<PrimaryButton>(button).onPressed, isNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, 650));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('thoughtInput')),
      'Today will be a good day.',
    );
    await tester.pump();
    await tester.drag(find.byType(ListView).first, const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(tester.widget<PrimaryButton>(button).onPressed, isNotNull);
  });

  testWidgets('New Thought returns to a clean input screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
    await tester.drag(find.byType(ListView).first, const Offset(0, -650));
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
