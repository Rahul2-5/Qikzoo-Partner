import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/approval/approval_status_model.dart';
import '../../../providers/approval/approval_provider.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';

class ApprovalScreen extends ConsumerWidget {
  const ApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalAsync = ref.watch(approvalStatusProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Application status')),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          child: approvalAsync.when(
            loading: () => const PageLoadingShimmer(),
            error: (_, __) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(approvalStatusProvider),
                child: const Text('Retry'),
              ),
            ),
            data: (status) => LayoutBuilder(
              builder: (context, constraints) {
                final minimumContentHeight =
                    constraints.maxHeight > AppSpacing.xxl
                        ? constraints.maxHeight - AppSpacing.xxl
                        : 0.0;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minimumContentHeight,
                    ),
                    child: Center(child: _ApprovalCard(status: status)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final ApprovalStatusModel status;
  const _ApprovalCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final (title, message, icon, color) = switch (status.state) {
      ApprovalState.pending => (
          'Application pending',
          'We have received your application.',
          Icons.schedule_outlined,
          AppColors.warning
        ),
      ApprovalState.underReview => (
          'Application under review',
          'Our team is reviewing your submitted documents.',
          Icons.manage_search_outlined,
          AppColors.primary
        ),
      ApprovalState.approved => (
          'You are approved',
          'You can now go online and start delivering.',
          Icons.verified_outlined,
          AppColors.secondary
        ),
      ApprovalState.rejected => (
          'Application needs attention',
          status.rejectionReason ??
              'Please update your application and try again.',
          Icons.error_outline,
          AppColors.error
        ),
    };
    return Semantics(
      container: true,
      label: '$title. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          boxShadow: AppShadows.card,
        ),
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
