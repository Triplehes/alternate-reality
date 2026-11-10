import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/access_provider.dart';
import '../providers/app_providers.dart';
import '../services/ai_service.dart';

Future<void> showPreviewAccess(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _AccessDialog());

class _AccessDialog extends ConsumerStatefulWidget {
  const _AccessDialog();
  @override
  ConsumerState<_AccessDialog> createState() => _AccessDialogState();
}

class _AccessDialogState extends ConsumerState<_AccessDialog> {
  final code = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Join the private preview'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter the personal invitation code shared with you. Keep your code private.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: code,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 256,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: 'Invitation code',
              counterText: '',
            ),
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('CANCEL'),
      ),
      FilledButton(
        onPressed: busy
            ? null
            : () async {
                setState(() {
                  busy = true;
                  error = null;
                });
                try {
                  await ref
                      .read(accessProvider.notifier)
                      .join(code.text, ref.read(aiConfigurationProvider));
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      error = e is AIServiceException
                          ? e.message
                          : 'Could not save your invitation. Please try again.';
                    });
                  }
                } finally {
                  if (mounted) setState(() => busy = false);
                }
              },
        child: Text(busy ? 'JOINING…' : 'JOIN PREVIEW'),
      ),
    ],
  );
}
