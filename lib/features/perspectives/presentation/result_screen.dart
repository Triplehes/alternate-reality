import 'package:alternate_reality/core/theme/app_theme.dart';
import 'package:alternate_reality/core/widgets/app_widgets.dart';
import 'package:alternate_reality/features/perspectives/application/reality_controller.dart';
import 'package:alternate_reality/features/perspectives/domain/reality.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    super.key,
    required this.entry,
    required this.onNewThought,
  });
  final RealityEntry entry;
  final VoidCallback onNewThought;
  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool revealed = false;
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => revealed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(realityControllerProvider, (previous, next) {
      if ((next.phase == ShiftPhase.success ||
              next.phase == ShiftPhase.error) &&
          mounted) {
        setState(() => revealed = true);
      }
    });
    final reduce = MediaQuery.disableAnimationsOf(context);
    final shiftState = ref.watch(realityControllerProvider);
    final entry = shiftState.entry ?? widget.entry;
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: PageWidth(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onNewThought,
                        icon: const Icon(Icons.close),
                      ),
                      const Spacer(),
                      const Flexible(child: BrandMark()),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: reduce
                            ? Duration.zero
                            : const Duration(milliseconds: 650),
                        child: revealed || reduce
                            ? SingleChildScrollView(
                                key: const ValueKey('result'),
                                child: Column(
                                  children: [
                                    const Text(
                                      'CURRENT REALITY',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 11,
                                        letterSpacing: 2.8,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    Text(
                                      '“${entry.alternateText}”',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(
                                            fontSize: 36,
                                            height: 1.25,
                                          ),
                                    ),
                                    const SizedBox(height: 26),
                                    Text(
                                      entry.mode.label.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11,
                                        letterSpacing: 1.7,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const Column(
                                key: ValueKey('loading'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.blur_on_rounded,
                                    color: AppColors.accent,
                                    size: 46,
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    'REALITY SHIFTING…',
                                    style: TextStyle(
                                      letterSpacing: 2,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  if (revealed || reduce)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.copy_rounded, size: 17),
                          label: const Text('COPY'),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: entry.alternateText),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reality copied.'),
                                ),
                              );
                            }
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.share_rounded, size: 17),
                          label: const Text('SHARE'),
                          onPressed: () async {
                            try {
                              final box =
                                  context.findRenderObject() as RenderBox?;
                              await SharePlus.instance.share(
                                ShareParams(
                                  text: entry.alternateText,
                                  sharePositionOrigin: box == null
                                      ? null
                                      : box.localToGlobal(Offset.zero) &
                                            box.size,
                                ),
                              );
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Sharing is unavailable. Use Copy to share this perspective.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.refresh_rounded, size: 17),
                          label: const Text('REGENERATE'),
                          onPressed: shiftState.phase == ShiftPhase.generating
                              ? null
                              : () {
                                  setState(() => revealed = false);
                                  ref
                                      .read(realityControllerProvider.notifier)
                                      .generate(
                                        entry.originalText,
                                        mode: entry.mode,
                                      );
                                },
                        ),
                      ],
                    ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'NEW THOUGHT',
                    onPressed: widget.onNewThought,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
