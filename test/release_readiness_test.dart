import 'dart:convert';

import 'package:alternate_reality/app/alternate_reality_app.dart';
import 'package:alternate_reality/core/storage/preferences_provider.dart';
import 'package:alternate_reality/core/theme/app_theme.dart';
import 'package:alternate_reality/core/widgets/app_widgets.dart';
import 'package:alternate_reality/features/history/data/reality_repository.dart';
import 'package:alternate_reality/features/onboarding/presentation/onboarding_screen.dart';
import 'package:alternate_reality/features/perspectives/application/perspective_providers.dart';
import 'package:alternate_reality/features/perspectives/data/ai_service.dart';
import 'package:alternate_reality/features/perspectives/domain/reality.dart';
import 'package:alternate_reality/features/perspectives/presentation/home_screen.dart';
import 'package:alternate_reality/features/settings/application/settings_providers.dart';
import 'package:alternate_reality/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

RealityEntry entry(int id) => RealityEntry(
  id: '$id',
  originalText: 'A thought',
  alternateText: 'A perspective',
  mode: RealityMode.positive,
  createdAt: DateTime.utc(2026).add(Duration(seconds: id)),
);
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('one damaged record does not hide valid legacy history', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesRealityRepository.key: [
        'bad JSON',
        jsonEncode(entry(1).toJson()),
        '{}',
      ],
    });
    final repo = SharedPreferencesRealityRepository(
      await SharedPreferences.getInstance(),
    );
    expect((await repo.getHistory()).single.id, '1');
  });
  test(
    'concurrent saves preserve both entries and exactly one current reality',
    () async {
      final repo = SharedPreferencesRealityRepository(
        await SharedPreferences.getInstance(),
      );
      await Future.wait([
        repo.saveReality(entry(1)),
        repo.saveReality(entry(2)),
      ]);
      expect((await repo.getHistory()).length, 2);
      expect(
        (await repo.getHistory()).where((e) => e.isCurrent).single.id,
        '2',
      );
      await repo.clearHistory();
      expect(await repo.getHistory(), isEmpty);
    },
  );
  test('history stays within its published limit', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesRealityRepository.key: List.generate(
        500,
        (i) => jsonEncode(entry(i).toJson()),
      ),
    });
    final repo = SharedPreferencesRealityRepository(
      await SharedPreferences.getInstance(),
    );
    await repo.saveReality(entry(500));
    final items = await repo.getHistory();
    expect(items.length, 500);
    expect(items.first.id, '500');
    expect(items.any((e) => e.id == '0'), isFalse);
  });
  test(
    'saved mode and current notification preference restore on restart',
    () async {
      SharedPreferences.setMockInitialValues({
        'selected_mode': 'literalNegation',
        'current_notification_enabled': false,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(preferencesProvider.future);
      expect(container.read(modeProvider), RealityMode.literalNegation);
      expect(container.read(notificationsEnabledProvider), false);
    },
  );
  testWidgets(
    'offline preview explains available features and does not submit a thought',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiConfigurationProvider.overrideWithValue(
              const AIConfiguration(baseUrl: '', accessToken: ''),
            ),
          ],
          child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('thoughtInput')),
        'I feel ready',
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -1400));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
      expect(find.textContaining('This offline preview'), findsOneWidget);
    },
  );
  testWidgets('startup storage failure offers retry', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWith(
            (ref) => throw StateError('Storage inaccessible'),
          ),
        ],
        child: const AlternateRealityApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TRY AGAIN'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });
  testWidgets('small screen and large text fit onboarding, home and settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final screen in <Widget>[
      OnboardingScreen(onComplete: () async {}),
      const HomeScreen(),
      const SettingsScreen(),
    ]) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiConfigurationProvider.overrideWithValue(
              const AIConfiguration(baseUrl: '', accessToken: ''),
            ),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            builder: (_, child) => MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: screen,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: screen.runtimeType.toString(),
      );
      if (find.byType(ListView).evaluate().isNotEmpty) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -1800));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: screen.runtimeType.toString(),
        );
      }
      await tester.pumpWidget(const SizedBox());
    }
  });
}
