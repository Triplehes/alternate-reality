import 'package:alternate_reality/core/theme/app_theme.dart';
import 'package:alternate_reality/core/widgets/app_widgets.dart';
import 'package:alternate_reality/features/motivation/application/motivation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailyMotivationCard extends ConsumerWidget {
  const DailyMotivationCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyMotivationProvider);
    final supported = ref.watch(dailyMotivationServiceProvider).supported;
    final time = TimeOfDay(
      hour: state.hour,
      minute: state.minute,
    ).format(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: AppColors.accent, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'TODAY\'S MOTIVATION',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            state.text,
            key: const Key('dailyMotivationText'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          if (state.enabled)
            Text(
              'Daily notification at $time',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            )
          else if (supported)
            TextButton(
              onPressed: state.busy
                  ? null
                  : () => ref
                        .read(dailyMotivationProvider.notifier)
                        .setEnabled(true),
              child: Text('NOTIFY ME DAILY AT $time'),
            ),
          if (state.error != null)
            Text(state.error!, style: const TextStyle(color: AppColors.accent)),
        ],
      ),
    );
  }
}
