import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/kumi_mascot.dart';
import '../../../shared/widgets/kumi_speech_bubble.dart';
import 'home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HomeController>().load();
    });
  }

  Future<void> _toggle(TaskItem task) async {
    final controller = context.read<HomeController>();
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    final profile = controller.profile;
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.lg,
              AppSpacing.screenPadding,
              AppSpacing.xxl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hai, ${profile?.name.split(' ').first ?? 'teman'}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('EEEE, d MMMM', 'id_ID').format(now),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Profil',
                    onPressed: () => context.go('/profile'),
                    icon: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.foxCream,
                      backgroundImage: profile?.pictureUrl != null
                          ? NetworkImage(profile!.pictureUrl!)
                          : null,
                      child: profile?.pictureUrl == null
                          ? Text(
                              (profile?.name.isNotEmpty ?? false)
                                  ? profile!.name[0].toUpperCase()
                                  : 'K',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ErrorRetry(
                    message: controller.error!,
                    onRetry: controller.load,
                  ),
                ),
              KumiMascotCard(
                dialogText: controller.dialogText,
                showBubble: controller.dialogText != null,
                mood: controller.celebrating ? KumiMood.happy : KumiMood.idle,
                onTapMascot: controller.tapMascot,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (controller.loading && profile == null)
                const Center(child: CircularProgressIndicator())
              else
                DailyProgressBar(
                  completed: controller.todayCompleted,
                  total: controller.todayTotal,
                ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jadwal berikutnya',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go('/tasks'),
                    child: const Text('Lihat semua'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!controller.loading && controller.upcomingTasks.isEmpty)
                const EmptyState(
                  title: 'Belum ada tugas hari ini',
                  message: 'Tambahkan satu tugas untuk memulai.',
                )
              else
                ...controller.upcomingTasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: TaskCard(task: task, onToggle: () => _toggle(task)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
