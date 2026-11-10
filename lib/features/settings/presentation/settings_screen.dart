import 'package:alternate_reality/core/widgets/app_widgets.dart';
import 'package:alternate_reality/features/history/application/history_providers.dart';
import 'package:alternate_reality/features/notifications/application/notification_providers.dart';
import 'package:alternate_reality/features/perspectives/application/perspective_providers.dart';
import 'package:alternate_reality/features/perspectives/application/reality_controller.dart';
import 'package:alternate_reality/features/preview_access/application/access_provider.dart';
import 'package:alternate_reality/features/preview_access/presentation/preview_access_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/preferences_card.dart';
import 'widgets/privacy_about_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                const PreferencesCard(),
                const SizedBox(height: 16),
                const PrivacyAboutCard(),
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
