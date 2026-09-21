import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../providers/app_providers.dart';
import 'widgets.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: PageWidth(
            child: CustomScrollView(
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(24, 28, 24, 10),
                  sliver: SliverToBoxAdapter(child: BrandMark()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Past realities',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                  ),
                ),
                history.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const SliverFillRemaining(
                    child: Center(child: Text("History couldn't be opened.")),
                  ),
                  data: (items) => items.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.blur_off_rounded,
                                  color: Colors.white24,
                                  size: 42,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Nothing has shifted yet.',
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Give me a thought.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final item = items[i];
                              return Dismissible(
                                key: ValueKey(item.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  color: Colors.red.shade900,
                                  child: const Icon(Icons.delete_outline),
                                ),
                                onDismissed: (_) async {
                                  await ref
                                      .read(repositoryProvider)
                                      .deleteReality(item.id);
                                  ref.invalidate(historyProvider);
                                },
                                child: GlassCard(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.originalText,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Icon(
                                          Icons.south_rounded,
                                          size: 17,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      Text(
                                        item.alternateText,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Text(
                                            item.mode.label.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.accent,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            DateFormat.yMMMd().add_jm().format(
                                              item.createdAt,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white30,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
