import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});
  final Future<void> Function() onComplete;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int index = 0;
  bool busy = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  static const pages = [
    ('YOUR THOUGHTS.', 'A different interpretation.'),
    ('SAY SOMETHING.', 'Type it, or let your voice cross over.'),
    ('SHIFT THE ANGLE.', "We'll show you another way it could be seen."),
    (
      'WELCOME TO\nTHE OTHER SIDE.',
      'Daily motivation stays on your device. When you request a perspective, your thought is sent to our AI service and OpenAI. Perspectives are creative possibilities, not facts or advice.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AmbientBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Align(alignment: Alignment.centerLeft, child: BrandMark()),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: pages.length,
                  onPageChanged: (value) => setState(() => index = value),
                  itemBuilder: (_, pageIndex) => Semantics(
                    label: '${pages[pageIndex].$1} ${pages[pageIndex].$2}',
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pages[pageIndex].$1,
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              pages[pageIndex].$2,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var dot = 0; dot < pages.length; dot++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: dot == index ? 28 : 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 7),
                      decoration: BoxDecoration(
                        color: dot == index ? AppColors.accent : Colors.white24,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            setState(() => busy = true);
                            try {
                              if (index == pages.length - 1) {
                                await widget.onComplete();
                              } else if (MediaQuery.disableAnimationsOf(
                                context,
                              )) {
                                controller.jumpToPage(index + 1);
                              } else {
                                await controller.nextPage(
                                  duration: const Duration(milliseconds: 450),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not save your progress. Please try again.',
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => busy = false);
                            }
                          },
                    child: Text(
                      index == pages.length - 1 ? 'GET STARTED' : 'CONTINUE',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
