import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/onboarding_status/onboarding_status_provider.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';

/// Consent is captured exactly once, atomically, during onboarding submit
/// (`POST /rider/onboarding/submit`) — there is no backend endpoint to
/// re-accept or re-record it later, so this screen is read-only: it
/// confirms what the rider already agreed to rather than pretending a
/// second "Accept" action here does anything real.
class AgreementScreen extends ConsumerWidget {
  const AgreementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(onboardingStatusProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Partner agreement')),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          child: statusAsync.when(
            loading: () => const PageLoadingShimmer(),
            error: (_, __) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(onboardingStatusProvider),
                child: const Text('Retry'),
              ),
            ),
            data: (status) {
              final submittedAt = status.submittedAt;
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sheet),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.fileCheck2,
                            color: AppColors.success, size: 32),
                        const SizedBox(height: AppSpacing.md),
                        Text('Terms of Service', style: AppTypography.h3),
                        const SizedBox(height: 4),
                        Text('Privacy Policy', style: AppTypography.h3),
                        const SizedBox(height: 4),
                        Text('Delivery Partner Agreement', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          submittedAt != null
                              ? 'You accepted these when you submitted your application on ${DateFormat('d MMMM yyyy').format(submittedAt.toLocal())}.'
                              : 'You accept these when you submit your partner application.',
                          style: AppTypography.body
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
