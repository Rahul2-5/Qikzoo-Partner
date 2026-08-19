import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/training/training_module_model.dart';
import '../../../providers/training/training_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(trainingModulesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Training')),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 640,
          child: modulesAsync.when(
            loading: () => const PageLoadingShimmer(),
            error: (_, __) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(trainingModulesProvider),
                child: const Text('Retry'),
              ),
            ),
            data: (modules) => modules.isEmpty
                ? const EmptyState(
                    message: 'No training modules are available right now.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    itemCount: modules.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, index) => _TrainingModuleCard(
                      module: modules[index],
                      onComplete: () async {
                        await ref
                            .read(trainingModulesProvider.notifier)
                            .markCompleted(modules[index].id);
                        if (context.mounted) {
                          AppSnackBar.success(
                            context,
                            '${modules[index].title} completed',
                          );
                        }
                      },
                    ),
                  ),
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
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final useStackedLayout = constraints.maxWidth < 400 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          final icon = Icon(
            module.isCompleted
                ? LucideIcons.checkCircle2
                : LucideIcons.playCircle,
            color: module.isCompleted ? AppColors.secondary : AppColors.primary,
            size: 22,
          );
          final details = _ModuleDetails(module: module);
          final action = TextButton(
            onPressed: module.isCompleted ? null : onComplete,
            child: Text(module.isCompleted ? 'Completed' : 'Complete'),
          );

          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.card,
            ),
            child: useStackedLayout
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          icon,
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: details),
                        ],
                      ),
                      Align(alignment: Alignment.centerRight, child: action),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: details),
                      const SizedBox(width: AppSpacing.sm),
                      action,
                    ],
                  ),
          );
        },
      );
}

class _ModuleDetails extends StatelessWidget {
  const _ModuleDetails({required this.module});

  final TrainingModuleModel module;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(module.title, style: AppTypography.bodyMedium),
        const SizedBox(height: 2),
        Text(module.description, style: AppTypography.body),
        const SizedBox(height: AppSpacing.xs),
        Text('${module.durationMinutes} min', style: AppTypography.caption),
      ],
    );
  }
}
