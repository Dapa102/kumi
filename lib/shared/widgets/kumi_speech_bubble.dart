import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import 'kumi_mascot.dart';

class KumiSpeechBubble extends StatelessWidget {
  const KumiSpeechBubble({super.key, required this.text, this.onDismiss});

  final String text;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
        ),
      ),
    );
  }
}

class KumiMascotCard extends StatelessWidget {
  const KumiMascotCard({
    super.key,
    required this.dialogText,
    required this.onTapMascot,
    this.showBubble = false,
    this.mood = KumiMood.idle,
  });

  final String? dialogText;
  final VoidCallback onTapMascot;
  final bool showBubble;
  final KumiMood mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.foxCream,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          KumiMascot(size: 140, mood: mood, onTap: onTapMascot),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: showBubble && dialogText != null
                ? KumiSpeechBubble(
                    key: ValueKey(dialogText),
                    text: dialogText!,
                  )
                : const SizedBox(height: 4),
          ),
        ],
      ),
    );
  }
}
