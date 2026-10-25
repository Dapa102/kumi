import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class AchievementTile extends StatelessWidget {
  const AchievementTile({super.key, required this.achievement, this.onTap});

  final Achievement achievement;
  final VoidCallback? onTap;

  IconData get _icon {
    if (achievement.code.startsWith('streak')) {
      return Icons.local_fire_department_rounded;
    }
    return Icons.military_tech_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final earned = achievement.earned;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: earned ? AppColors.foxCream : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: earned
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.secondary.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              earned ? _icon : Icons.lock_outline_rounded,
              size: 30,
              color: earned ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              achievement.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: earned ? AppColors.secondary : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
