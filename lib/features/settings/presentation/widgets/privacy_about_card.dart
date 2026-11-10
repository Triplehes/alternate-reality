import 'package:alternate_reality/core/theme/app_theme.dart';
import 'package:alternate_reality/core/widgets/app_widgets.dart';
import 'package:flutter/material.dart';

class PrivacyAboutCard extends StatelessWidget {
  const PrivacyAboutCard({super.key});
  @override
  Widget build(BuildContext context) => const GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRIVACY',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 11,
            letterSpacing: 1.6,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Your latest 500 thoughts and perspectives stay on this device until you clear them. Submitting a thought sends it to our AI service and OpenAI to create your perspective. Daily motivation works offline. Voice input uses your device’s speech service. Avoid sharing sensitive personal information.',
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
        SizedBox(height: 22),
        Text(
          'ABOUT',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 11,
            letterSpacing: 1.6,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Alternate Reality 2.0.0\nExplore hopeful, darker and literal perspectives. Interpretations are creative possibilities, not advice or predictions.',
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
      ],
    ),
  );
}
