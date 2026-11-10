import 'dart:async';

import 'package:alternate_reality/core/storage/preferences_provider.dart';
import 'package:alternate_reality/core/theme/app_theme.dart';
import 'package:alternate_reality/core/widgets/app_widgets.dart';
import 'package:alternate_reality/features/history/application/history_providers.dart';
import 'package:alternate_reality/features/perspectives/application/perspective_providers.dart';
import 'package:alternate_reality/features/perspectives/application/reality_controller.dart';
import 'package:alternate_reality/features/perspectives/data/ai_service.dart';
import 'package:alternate_reality/features/perspectives/domain/reality.dart';
import 'package:alternate_reality/features/perspectives/presentation/home_screen.dart';
import 'package:alternate_reality/features/settings/application/settings_providers.dart';
import 'package:alternate_reality/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingAI implements AIService {
  final modes = <RealityMode>[];
  final pending = <Completer<String>>[];
  @override
  Future<String> generateAlternateReality(String input, RealityMode mode) {
    modes.add(mode);
    final completer = Completer<String>();
    pending.add(completer);
    return completer.future;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'positive and literal modes select, generate, persist and recover after failed regeneration',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final ai = RecordingAI();
      final container = ProviderContainer(
        overrides: [
          aiConfigurationProvider.overrideWithValue(
            const AIConfiguration(
              baseUrl: 'https://preview.example',
              accessToken: 'test-token-with-at-least-32-characters',
            ),
          ),
          aiServiceProvider.overrideWithValue(ai),
          notificationsEnabledProvider.overrideWith((ref) => false),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('thoughtInput')),
        'She enjoys her job.',
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -800));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mode-positive')));
      await tester.pump();
      expect(container.read(modeProvider), RealityMode.positive);
      expect(find.text(RealityMode.positive.description), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('mode-literalNegation')));
      await tester.pump();
      expect(container.read(modeProvider), RealityMode.literalNegation);
      await tester.scrollUntilVisible(
        find.byType(PrimaryButton),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(ai.modes, [RealityMode.literalNegation]);
      ai.pending.first.complete('She does not enjoy her job.');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('“She does not enjoy her job.”'), findsOneWidget);
      expect(
        (await container.read(repositoryProvider).getHistory()).single.mode,
        RealityMode.literalNegation,
      );
      await tester.tap(find.text('REGENERATE'));
      await tester.pumpAndSettle();
      expect(ai.modes.last, RealityMode.literalNegation);
      ai.pending.last.completeError(
        const AIServiceException('AI is temporarily unavailable.'),
      );
      await tester.pumpAndSettle();
      expect(find.text('“She does not enjoy her job.”'), findsOneWidget);
      expect(find.text('REGENERATE'), findsOneWidget);
      expect((await container.read(repositoryProvider).getHistory()).length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    },
  );
  test(
    'reset discards a late response and duplicate submissions are ignored',
    () async {
      final ai = RecordingAI();
      final container = ProviderContainer(
        overrides: [
          aiConfigurationProvider.overrideWithValue(
            const AIConfiguration(
              baseUrl: 'https://preview.example',
              accessToken: 'test-token-with-at-least-32-characters',
            ),
          ),
          aiServiceProvider.overrideWithValue(ai),
          notificationsEnabledProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);
      await container.read(preferencesProvider.future);
      final controller = container.read(realityControllerProvider.notifier);
      final request = controller.generate('Hello', mode: RealityMode.positive);
      await Future<void>.delayed(Duration.zero);
      await controller.generate('Duplicate', mode: RealityMode.literalNegation);
      expect(ai.modes.length, 1);
      controller.reset();
      ai.pending.single.complete('A positive result');
      await request;
      expect(container.read(realityControllerProvider).phase, ShiftPhase.idle);
      expect(await container.read(repositoryProvider).getHistory(), isEmpty);
    },
  );
  testWidgets(
    'settings keeps mode selection without developer connection details',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: buildTheme(), home: const SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<RealityMode>));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Positive').last,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Positive').last);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('AI CONNECTION'), findsNothing);
      expect(find.text('Setup required'), findsNothing);
      expect(find.text('Server configured'), findsNothing);
      expect(find.text('PRIVACY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
