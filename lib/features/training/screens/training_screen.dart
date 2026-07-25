import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/training/training_module_model.dart';
import '../../../providers/training/training_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/misc/empty_state.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(trainingModulesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Training')),
      body: modulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: TextButton(onPressed: () => ref.invalidate(trainingModulesProvider), child: const Text('Retry'))),
        data: (modules) => modules.isEmpty
            ? const EmptyState(message: 'No training modules are available right now.')
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: modules.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, index) => _TrainingModuleCard(
                  module: modules[index],
                  onComplete: () async {
                    await ref.read(trainingModulesProvider.notifier).markCompleted(modules[index].id);
                    if (context.mounted) AppSnackBar.success(context, '${modules[index].title} completed');
                  },
                ),
              ),
      ),
    );
  }
}

class _TrainingModuleCard extends StatelessWidget {
  final TrainingModuleModel module;
  final Future<void> Function() onComplete;
  const _TrainingModuleCard({required this.module, required this.onComplete});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(module.isCompleted ? Icons.check_circle : Icons.play_circle_outline,
              color: module.isCompleted ? AppColors.secondary : AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(module.title, style: AppTypography.bodyMedium),
            const SizedBox(height: 2),
            Text(module.description, style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text('${module.durationMinutes} min', style: AppTypography.caption),
          ])),
          TextButton(
            onPressed: module.isCompleted ? null : onComplete,
            child: Text(module.isCompleted ? 'Completed' : 'Complete'),
          ),
        ]),
      );
}
