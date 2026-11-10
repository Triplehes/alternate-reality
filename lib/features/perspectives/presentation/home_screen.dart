import 'package:alternate_reality/core/theme/app_theme.dart';
import 'package:alternate_reality/core/widgets/app_widgets.dart';
import 'package:alternate_reality/features/motivation/presentation/daily_motivation_card.dart';
import 'package:alternate_reality/features/perspectives/application/perspective_providers.dart';
import 'package:alternate_reality/features/perspectives/application/reality_controller.dart';
import 'package:alternate_reality/features/perspectives/domain/reality.dart';
import 'package:alternate_reality/features/perspectives/presentation/result_screen.dart';
import 'package:alternate_reality/features/preview_access/presentation/preview_access_dialog.dart';
import 'package:alternate_reality/features/settings/application/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final text = TextEditingController();
  bool hasText = false;
  bool _resultRouteOpen = false;
  @override
  void initState() {
    super.initState();
    text.addListener(() {
      setState(() => hasText = text.text.trim().isNotEmpty);
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
        if (_resultRouteOpen) return;
        _resultRouteOpen = true;
        final navigator = Navigator.of(context);
        navigator
            .push(
              MaterialPageRoute(
                builder: (_) => ResultScreen(
                  entry: next.entry!,
                  onNewThought: () {
                    ref.read(realityControllerProvider.notifier).reset();
                    text.clear();
                    navigator.pop();
                  },
                ),
              ),
            )
            .whenComplete(() => _resultRouteOpen = false);
      }
    });
    final state = ref.watch(realityControllerProvider);
    final mode = ref.watch(modeProvider);
    final ai = ref.watch(aiConfigurationProvider);
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: PageWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 50),
              children: [
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const BrandMark(),
                    Text(
                      'See things differently.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const DailyMotivationCard(),
                const SizedBox(height: 32),
                Text(
                  'One thought.\nAnother perspective.',
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
                        maxLength: 600,
                        buildCounter: (
                          context, {
                          required currentLength,
                          required isFocused,
                          required maxLength,
                        }) => null,
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
                              onPressed: state.phase == ShiftPhase.generating
                                  ? null
                                  : () async {
                                      HapticFeedback.selectionClick();
                                      if (state.phase == ShiftPhase.listening) {
                                        await ref
                                            .read(
                                              realityControllerProvider
                                                  .notifier,
                                            )
                                            .stopListening();
                                      } else {
                                        await ref
                                            .read(
                                              realityControllerProvider
                                                  .notifier,
                                            )
                                            .listen((value) {
                                              if (!mounted) return;
                                              value = value.characters
                                                  .take(600)
                                                  .toString();
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
                const Text(
                  'CHOOSE A PERSPECTIVE',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final item in [
                      RealityMode.positive,
                      RealityMode.literalNegation,
                      ...RealityMode.values.where(
                        (m) =>
                            m != RealityMode.positive &&
                            m != RealityMode.literalNegation,
                      ),
                    ])
                      ChoiceChip(
                        key: ValueKey('mode-${item.name}'),
                        label: Text(item.label),
                        selected: item == mode,
                        onSelected: state.phase == ShiftPhase.generating
                            ? null
                            : (_) async {
                                try {
                                  await selectMode(ref, item);
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
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  mode.description,
                  key: const Key('modeDescription'),
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
                if (!ai.isConfigured) ...[
                  const SizedBox(height: 12),
                  Text(
                    ai.endpoint == null
                        ? 'This offline preview includes daily motivation and reminders. Online perspectives will arrive in a connected update.'
                        : 'Have an invitation? Join the private preview to explore all nine perspectives.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  if (ai.endpoint != null)
                    TextButton(
                      onPressed: () => showPreviewAccess(context),
                      child: const Text('ENTER INVITATION'),
                    ),
                ],
                const SizedBox(height: 18),
                PrimaryButton(
                  label: state.phase == ShiftPhase.generating
                      ? 'REALITY SHIFTING…'
                      : 'ALTER REALITY',
                  icon: Icons.auto_awesome_rounded,
                  onPressed:
                      hasText &&
                          ai.isConfigured &&
                          state.phase != ShiftPhase.generating &&
                          state.phase != ShiftPhase.listening
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
