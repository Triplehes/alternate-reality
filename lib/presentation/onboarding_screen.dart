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
  static const pages = [
    ('YOUR THOUGHTS.', 'A different interpretation.'),
    ('SAY SOMETHING.', 'Type it, or let your voice cross over.'),
    ('SHIFT THE ANGLE.', "We'll show you another way it could be seen."),
    (
      'WELCOME TO\nTHE OTHER SIDE.',
      'Reality was always a matter of perspective.',
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
                    child: Column(
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
              Row(
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
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      if (index == pages.length - 1) {
                        await widget.onComplete();
                      } else {
                        await controller.nextPage(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                        );
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
