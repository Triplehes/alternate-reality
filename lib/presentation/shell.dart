import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/motivation_provider.dart';
import '../providers/app_providers.dart';

import 'history_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        ref.read(realityControllerProvider).phase == ShiftPhase.listening) {
      ref.read(realityControllerProvider.notifier).stopListening();
    }
    if (state == AppLifecycleState.resumed) {
      ref.read(dailyMotivationProvider.notifier).refresh();
    }
  }

  int index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: index,
      children: const [HomeScreen(), HistoryScreen(), SettingsScreen()],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        if (ref.read(realityControllerProvider).phase == ShiftPhase.listening) {
          ref.read(realityControllerProvider.notifier).stopListening();
        }
        setState(() => index = i);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.blur_on_rounded),
          label: 'Shift',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_rounded),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.tune_rounded),
          label: 'Settings',
        ),
      ],
    ),
  );
}
