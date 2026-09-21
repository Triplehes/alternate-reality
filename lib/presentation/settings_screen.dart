import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../domain/reality.dart';
import '../providers/app_providers.dart';
import 'widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);
    final notifications = ref.watch(notificationsEnabledProvider);
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: PageWidth(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const BrandMark(),
                const SizedBox(height: 42),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 30),
                GlassCard(
                  child: Column(
                    children: [
                      DropdownButtonFormField<RealityMode>(
                        initialValue: mode,
                        decoration: const InputDecoration(
                          labelText: 'DEFAULT REALITY MODE',
                        ),
                        items: RealityMode.values
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.label),
                              ),
                            )
                            .toList(),
                        onChanged: (m) {
                          if (m != null) {
                            ref.read(modeProvider.notifier).state = m;
                          }
                        },
                      ),
                      const Divider(height: 36, color: Colors.white10),
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Current reality notification'),
                          subtitle: const Text(
                            'Updated after every shift',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          value: notifications,
                          onChanged: (v) async {
                            ref
                                    .read(notificationsEnabledProvider.notifier)
                                    .state =
                                v;
                            if (!v) {
                              await ref
                                  .read(notificationServiceProvider)
                                  .cancelCurrentReality();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRIVACY',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          letterSpacing: 1.6,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Your history stays on this device. Thoughts are sent only to the configured AI provider when an API key is supplied.',
                        style: TextStyle(color: AppColors.muted, height: 1.5),
                      ),
                      SizedBox(height: 22),
                      Text(
                        'ABOUT',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          letterSpacing: 1.6,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Alternate Reality 1.0.0\nA deliberately darker angle—not advice, prophecy, or truth.',
                        style: TextStyle(color: AppColors.muted, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final accepted = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Clear every reality?'),
                        content: const Text('This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('CANCEL'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('CLEAR'),
                          ),
                        ],
                      ),
                    );
                    if (accepted == true) {
                      await ref.read(repositoryProvider).clearHistory();
                      await ref
                          .read(notificationServiceProvider)
                          .cancelCurrentReality();
                      ref.invalidate(historyProvider);
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('CLEAR HISTORY'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
