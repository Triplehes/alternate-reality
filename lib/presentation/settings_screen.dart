import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../providers/motivation_provider.dart';
import '../providers/access_provider.dart';
import 'preview_access.dart';

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
    final daily = ref.watch(dailyMotivationProvider);
    final dailySupported = ref.watch(dailyMotivationServiceProvider).supported;
    final notifications = ref.watch(notificationsEnabledProvider);
    final notificationSupported =
        !kIsWeb &&
        {
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform);
    final ai = ref.watch(aiConfigurationProvider);
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
                        isExpanded: true,
                        itemHeight: null,
                        key: ValueKey(mode),
                        initialValue: mode,
                        decoration: const InputDecoration(
                          labelText: 'REALITY MODE',
                        ),
                        items: RealityMode.values
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.label),
                              ),
                            )
                            .toList(),
                        onChanged: (m) async {
                          if (m == null) return;
                          try {
                            await selectMode(ref, m);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not save your preference. Please try again.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const Divider(height: 36, color: Colors.white10),
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          key: const Key('dailyMotivationSwitch'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Daily motivation notification'),
                          subtitle: Text(
                            dailySupported
                                ? 'A different message each day. Separate from your current reality.'
                                : 'Daily scheduling is unavailable on this platform.',
                          ),
                          value: daily.enabled,
                          onChanged: !dailySupported || daily.busy
                              ? null
                              : (value) => ref
                                    .read(dailyMotivationProvider.notifier)
                                    .setEnabled(value),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Daily motivation time'),
                          subtitle: Text(
                            '${TimeOfDay(hour: daily.hour, minute: daily.minute).format(context)} · phone local time',
                          ),
                          trailing: const Icon(Icons.schedule),
                          enabled: dailySupported && !daily.busy,
                          onTap: !dailySupported || daily.busy
                              ? null
                              : () async {
                                  final selected = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(
                                      hour: daily.hour,
                                      minute: daily.minute,
                                    ),
                                  );
                                  if (selected != null && context.mounted) {
                                    await ref
                                        .read(dailyMotivationProvider.notifier)
                                        .setTime(
                                          selected.hour,
                                          selected.minute,
                                        );
                                  }
                                },
                        ),
                      ),
                      if (daily.error != null)
                        Text(
                          daily.error!,
                          style: const TextStyle(color: AppColors.accent),
                        ),
                      if (!kIsWeb &&
                          (defaultTargetPlatform == TargetPlatform.iOS ||
                              defaultTargetPlatform == TargetPlatform.macOS))
                        const Text(
                          'Open the app at least once every 30 days to renew daily reminders. Your device may keep earlier daily notifications in the same group.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      const Divider(height: 36, color: Colors.white10),
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Current reality notification'),
                          subtitle: Text(
                            notificationSupported
                                ? 'Updated after every shift. May appear on your lock screen.'
                                : 'Available in the mobile app.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          value: notifications,
                          onChanged: !notificationSupported
                              ? null
                              : (v) async {
                                  try {
                                    if (v &&
                                        !await ref
                                            .read(
                                              localNotificationServiceProvider,
                                            )
                                            .requestPermission()) {
                                      throw StateError(
                                        'Permission unavailable',
                                      );
                                    }
                                    final prefs = await ref.read(
                                      preferencesProvider.future,
                                    );
                                    if (!await prefs.setBool(
                                      'current_notification_enabled',
                                      v,
                                    )) {
                                      throw StateError('Storage failed');
                                    }
                                    ref
                                            .read(
                                              notificationsEnabledProvider
                                                  .notifier,
                                            )
                                            .state =
                                        v;
                                    if (!v) {
                                      await ref
                                          .read(notificationServiceProvider)
                                          .cancelCurrentReality();
                                    } else {
                                      final current = await ref
                                          .read(repositoryProvider)
                                          .getCurrentReality();
                                      if (current != null &&
                                          ref.read(
                                            notificationsEnabledProvider,
                                          )) {
                                        await ref
                                            .read(notificationServiceProvider)
                                            .showCurrentReality(
                                              current.alternateText,
                                            );
                                      }
                                    }
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Could not update notifications. Check notification permission in your device settings and try again.',
                                              ),
                                            ),
                                          );
                                    }
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
                        'Your latest 500 thoughts and perspectives stay on this device until you clear them. Submitting a thought sends it to our AI service and OpenAI to create your perspective. Daily motivation works offline. Voice input uses your device’s speech service. Avoid sharing sensitive personal information.',
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
                        'Alternate Reality 2.0.0\nExplore hopeful, darker and literal perspectives. Interpretations are creative possibilities, not advice or predictions.',
                        style: TextStyle(color: AppColors.muted, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (ai.endpoint != null) ...[
                  TextButton.icon(
                    icon: const Icon(Icons.vpn_key_outlined),
                    label: Text(
                      ai.isConfigured
                          ? 'CHANGE INVITATION'
                          : 'JOIN PRIVATE PREVIEW',
                    ),
                    onPressed: () => showPreviewAccess(context),
                  ),
                  if ((ref.watch(accessProvider).value ?? '').isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        try {
                          await ref.read(accessProvider.notifier).leave();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not remove the invitation. Please try again.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('REMOVE INVITATION'),
                    ),
                  const SizedBox(height: 16),
                ],
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
                      try {
                        ref.read(realityControllerProvider.notifier).reset();
                        await ref.read(repositoryProvider).clearHistory();
                        ref.invalidate(historyProvider);
                        await ref
                            .read(notificationServiceProvider)
                            .cancelCurrentReality();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('History cleared.')),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not finish clearing history. Please try again.',
                              ),
                            ),
                          );
                        }
                      }
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
