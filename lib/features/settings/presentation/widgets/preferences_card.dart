import 'package:alternate_reality/core/storage/preferences_provider.dart';
import 'package:alternate_reality/core/theme/app_theme.dart';
import 'package:alternate_reality/core/widgets/app_widgets.dart';
import 'package:alternate_reality/features/history/application/history_providers.dart';
import 'package:alternate_reality/features/motivation/application/motivation_provider.dart';
import 'package:alternate_reality/features/notifications/application/notification_providers.dart';
import 'package:alternate_reality/features/perspectives/domain/reality.dart';
import 'package:alternate_reality/features/settings/application/settings_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreferencesCard extends ConsumerWidget {
  const PreferencesCard({super.key});
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
    return GlassCard(
      child: Column(
        children: [
          DropdownButtonFormField<RealityMode>(
            isExpanded: true,
            itemHeight: null,
            key: ValueKey(mode),
            initialValue: mode,
            decoration: const InputDecoration(labelText: 'REALITY MODE'),
            items: RealityMode.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
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
                            .setTime(selected.hour, selected.minute);
                      }
                    },
            ),
          ),
          if (daily.error != null)
            Text(daily.error!, style: const TextStyle(color: AppColors.accent)),
          if (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS))
            const Text(
              'Open the app at least once every 30 days to renew daily reminders. Your device may keep earlier daily notifications in the same group.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
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
                                .read(localNotificationServiceProvider)
                                .requestPermission()) {
                          throw StateError('Permission unavailable');
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
                        ref.read(notificationsEnabledProvider.notifier).state =
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
                              ref.read(notificationsEnabledProvider)) {
                            await ref
                                .read(notificationServiceProvider)
                                .showCurrentReality(current.alternateText);
                          }
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
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
    );
  }
}
