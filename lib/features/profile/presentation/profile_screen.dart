import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import 'profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileController>().load();
    });
  }

  Future<void> _editName() async {
    final controller = context.read<ProfileController>();
    final textController = TextEditingController(
      text: controller.profile?.name ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit nama'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: textController,
            autofocus: true,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Nama'),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Nama tidak boleh kosong';
              if (text.length > 100) return 'Maksimum 100 karakter';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final ok = await controller.updateName(textController.text.trim());
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error ?? 'Gagal menyimpan nama.')),
      );
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Kumi?'),
        content: const Text('Kamu perlu masuk kembali untuk melihat tugasmu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<AuthController>().signOut();
    if (mounted) context.go('/login');
  }

  void _showAchievement(Achievement achievement) {
    showModalBottomSheet<void>(
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
            Icon(
              achievement.earned
                  ? Icons.military_tech_rounded
                  : Icons.lock_outline_rounded,
              size: 56,
              color: achievement.earned ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              achievement.name,
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
            if (achievement.earnedAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Diraih ${DateFormat('d MMM yyyy', 'id_ID').format(achievement.earnedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final profile = controller.profile;

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
              Text(
                'Profil',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (controller.loading && profile == null)
                const Center(child: CircularProgressIndicator())
              else if (controller.error != null && profile == null)
                ErrorRetry(message: controller.error!, onRetry: controller.load)
              else ...[
                Center(
                  child: CircleAvatar(
                    radius: 44,
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
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  profile?.name ?? '-',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  profile?.email ?? '-',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton(
                    onPressed: _editName,
                    child: const Text('Edit nama'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    StatCard(
                      label: 'Streak',
                      value: '${profile?.currentStreak ?? 0}',
                      icon: Icons.local_fire_department_rounded,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    StatCard(
                      label: 'Selesai',
                      value: '${profile?.completedTasks ?? 0}',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Achievement',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${controller.earnedCount} / ${controller.achievements.length}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (controller.achievements.isEmpty)
                  const EmptyState(
                    title: 'Belum ada badge',
                    message: 'Selesaikan tugas pertamamu untuk membuka badge.',
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.95,
                        ),
                    itemCount: controller.achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = controller.achievements[index];
                      return AchievementTile(
                        achievement: achievement,
                        onTap: () => _showAchievement(achievement),
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton(
                  onPressed: _confirmSignOut,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.danger,
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text('Keluar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
