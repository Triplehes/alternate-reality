import 'package:alternate_reality/domain/reality.dart';
import 'package:alternate_reality/presentation/home_screen.dart';
import 'package:alternate_reality/services/ai_service.dart';
import 'package:alternate_reality/presentation/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(prompt, contains('plain-text'));
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
}
