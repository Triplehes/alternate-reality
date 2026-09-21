import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'presentation/shell.dart';
import 'presentation/onboarding_screen.dart';
import 'providers/app_providers.dart';

class AlternateRealityApp extends ConsumerWidget {
  const AlternateRealityApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'Alternate Reality',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: ref
        .watch(preferencesProvider)
        .when(
          loading: () => const Scaffold(
            body: Center(
              child: Icon(
                Icons.blur_on_rounded,
                color: AppColors.accent,
                size: 38,
              ),
            ),
          ),
          error: (_, _) => const AppShell(),
          data: (prefs) => prefs.getBool('onboarding_complete') == true
              ? const AppShell()
              : OnboardingScreen(
                  onComplete: () async {
                    await prefs.setBool('onboarding_complete', true);
                    ref.invalidate(preferencesProvider);
                  },
                ),
        ),
  );
}
