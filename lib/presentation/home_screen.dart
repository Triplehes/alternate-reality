import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../domain/reality.dart';
import '../providers/app_providers.dart';
import 'result_screen.dart';
import 'widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final text = TextEditingController();
  bool hasText = false;
  @override
  void initState() {
    super.initState();
    text.addListener(() {
      if (hasText != text.text.trim().isNotEmpty) {
        setState(() => hasText = !hasText);
      }
    });
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(realityControllerProvider, (old, next) {
      if (next.phase == ShiftPhase.error && next.message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.message!)));
      }
      if (next.phase == ShiftPhase.success && next.entry != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              entry: next.entry!,
              onNewThought: () {
                Navigator.pop(context);
                text.clear();
                ref.read(realityControllerProvider.notifier).reset();
              },
            ),
          ),
        );
      }
    });
    final state = ref.watch(realityControllerProvider);
    final mode = ref.watch(modeProvider);
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: PageWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 50),
              children: [
                Row(
                  children: [
                    const BrandMark(),
                    const Spacer(),
                    Text(
                      'See things differently.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 64),
                Text(
                  'Give reality\nsomething to ruin.',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 16),
                const Text(
                  'A thought enters. Another interpretation leaves.',
                  style: TextStyle(color: AppColors.muted, fontSize: 16),
                ),
                const SizedBox(height: 36),
                GlassCard(
                  child: Column(
                    children: [
                      TextField(
                        key: const Key('thoughtInput'),
                        controller: text,
                        minLines: 4,
                        maxLines: 8,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'What are you thinking?',
                          hintStyle: TextStyle(
                            color: Colors.white30,
                            fontSize: 21,
                          ),
                        ),
                        style: const TextStyle(fontSize: 21, height: 1.45),
                      ),
                      const Divider(color: Colors.white10),
                      Row(
                        children: [
                          Semantics(
                            button: true,
                            label: state.phase == ShiftPhase.listening
                                ? 'Stop recording'
                                : 'Start voice input',
                            child: IconButton.filledTonal(
                              icon: Icon(
                                state.phase == ShiftPhase.listening
                                    ? Icons.stop_rounded
                                    : Icons.mic_none_rounded,
                                color: state.phase == ShiftPhase.listening
                                    ? AppColors.accent
                                    : Colors.white,
                              ),
                              onPressed: () async {
                                HapticFeedback.selectionClick();
                                if (state.phase == ShiftPhase.listening) {
                                  await ref
                                      .read(realityControllerProvider.notifier)
                                      .stopListening();
                                } else {
                                  await ref
                                      .read(realityControllerProvider.notifier)
                                      .listen((value) {
                                        text.text = value;
                                        text.selection =
                                            TextSelection.collapsed(
                                              offset: value.length,
                                            );
                                      });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (state.phase == ShiftPhase.listening)
                            const Text(
                              'LISTENING…',
                              style: TextStyle(
                                color: AppColors.accent,
                                letterSpacing: 1.5,
                                fontSize: 11,
                              ),
                            ),
                          const Spacer(),
                          Text(
                            '${text.text.length}/600',
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final item in RealityMode.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(item.label),
                            selected: item == mode,
                            onSelected: (_) =>
                                ref.read(modeProvider.notifier).state = item,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: state.phase == ShiftPhase.generating
                      ? 'REALITY SHIFTING…'
                      : 'ALTER REALITY',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: hasText && state.phase != ShiftPhase.generating
                      ? () {
                          FocusScope.of(context).unfocus();
                          HapticFeedback.mediumImpact();
                          ref
                              .read(realityControllerProvider.notifier)
                              .generate(text.text);
                        }
                      : null,
                ),
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    'Your reality is about to change.',
                    style: TextStyle(color: Colors.white30, fontSize: 12),
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
