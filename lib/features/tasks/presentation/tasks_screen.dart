import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/models.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../presentation/task_form_sheet.dart';
import '../presentation/tasks_controller.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _initialized = false;
  bool _permissionRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final tasksController = context.read<TasksController>();
      final notifications = context.read<NotificationService>();
      await tasksController.load();
      if (!_permissionRequested) {
        _permissionRequested = true;
        await notifications.requestPermission();
      }
    });
  }

  Future<void> _openForm({TaskItem? task}) async {
    final saved = await showModalBottomSheet<TaskItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => TaskFormSheet(task: task),
    );
    if (saved != null && mounted) {
      await context.read<TasksController>().load();
    }
  }

  Future<void> _confirmDelete(TaskItem task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus tugas ini?'),
        content: Text('"${task.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final ok = await context.read<TasksController>().deleteTask(task);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<TasksController>().error ?? 'Gagal menghapus.',
          ),
        ),
      );
    }
  }

  Future<void> _toggle(TaskItem task) async {
    final controller = context.read<TasksController>();
    final gamification = await controller.toggleTask(task);
    if (!mounted || gamification == null) return;

    for (final achievement in gamification.newAchievements) {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.military_tech_rounded,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Badge baru: ${achievement.name}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final controller = context.read<TasksController>();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('id'),
    );
    if (picked != null) controller.setDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TasksController>();
    final isToday = DateUtils.isSameDay(
      controller.selectedDate,
      DateTime.now(),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tugas',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Hari sebelumnya',
                          onPressed: () => controller.shiftDate(-1),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: _pickDate,
                            child: Text(
                              isToday
                                  ? 'Hari ini, ${DateFormat('d MMM', 'id_ID').format(controller.selectedDate)}'
                                  : DateFormat(
                                      'd MMM yyyy',
                                      'id_ID',
                                    ).format(controller.selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hari berikutnya',
                          onPressed: () => controller.shiftDate(1),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        selected: controller.statusFilter == 'all',
                        onSelected: () => controller.setStatusFilter('all'),
                      ),
                      _FilterChip(
                        label: 'Belum',
                        selected: controller.statusFilter == 'pending',
                        onSelected: () => controller.setStatusFilter('pending'),
                      ),
                      _FilterChip(
                        label: 'Selesai',
                        selected: controller.statusFilter == 'completed',
                        onSelected: () =>
                            controller.setStatusFilter('completed'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: _buildList(controller),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Tambah tugas',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildList(TasksController controller) {
    if (controller.loading && controller.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.tasks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          ErrorRetry(message: controller.error!, onRetry: controller.load),
        ],
      );
    }

    if (controller.tasks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          EmptyState(
            title: 'Tidak ada tugas',
            message: 'Tambahkan tugas untuk tanggal ini.',
            actionLabel: 'Tambah tugas',
            onAction: () => _openForm(),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        96,
      ),
      children: [
        if (controller.pendingTasks.isNotEmpty) ...[
          _SectionHeader(
            label: 'BELUM SELESAI (${controller.pendingTasks.length})',
          ),
          ...controller.pendingTasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Dismissible(
                key: ValueKey('pending-${task.id}'),
                background: _swipeBackground(alignEnd: false),
                secondaryBackground: _swipeBackground(alignEnd: true),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await _toggle(task);
                    return false;
                  }
                  await _confirmDelete(task);
                  return false;
                },
                child: TaskCard(
                  task: task,
                  onToggle: () => _toggle(task),
                  onTap: () => _openForm(task: task),
                  onEdit: () => _openForm(task: task),
                  onDelete: () => _confirmDelete(task),
                ),
              ),
            ),
          ),
        ],
        if (controller.completedTasks.isNotEmpty) ...[
          _SectionHeader(
            label: 'SELESAI (${controller.completedTasks.length})',
          ),
          ...controller.completedTasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Dismissible(
                key: ValueKey('completed-${task.id}'),
                background: _swipeBackground(alignEnd: false),
                secondaryBackground: _swipeBackground(alignEnd: true),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await _toggle(task);
                    return false;
                  }
                  await _confirmDelete(task);
                  return false;
                },
                child: TaskCard(
                  task: task,
                  onToggle: () => _toggle(task),
                  onTap: () => _openForm(task: task),
                  onEdit: () => _openForm(task: task),
                  onDelete: () => _confirmDelete(task),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _swipeBackground({required bool alignEnd}) {
    return Container(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: (alignEnd ? AppColors.danger : AppColors.accent).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Icon(
        alignEnd ? Icons.delete_outline_rounded : Icons.check_rounded,
        color: alignEnd ? AppColors.danger : AppColors.accent,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryDark : AppColors.secondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.4)
            : AppColors.secondary.withValues(alpha: 0.1),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
