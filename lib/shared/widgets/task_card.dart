import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  Color get _metaColor {
    if (task.isCompleted) return AppColors.muted;
    if (task.isOverdue) return AppColors.danger;
    if (task.isDueSoon) return AppColors.warning;
    return AppColors.muted;
  }

  String get _metaLabel {
    final time = DateFormat('HH.mm').format(task.dueTime);
    if (task.isCompleted) return time;
    if (task.isOverdue) return '$time · Terlambat';
    if (task.isDueSoon) return '$time · Segera';
    return time;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Semantics(
                label: task.isCompleted
                    ? 'Tandai belum selesai'
                    : 'Tandai selesai',
                child: IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    task.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: task.isCompleted
                        ? AppColors.accent
                        : AppColors.muted,
                  ),
                  tooltip: task.isCompleted ? 'Belum selesai' : 'Selesai',
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? AppColors.muted
                            : AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _metaLabel,
                      style: textTheme.bodySmall?.copyWith(color: _metaColor),
                    ),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  tooltip: 'Menu tugas',
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
