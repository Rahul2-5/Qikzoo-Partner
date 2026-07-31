import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';

class IncentivesScreen extends StatelessWidget {
  const IncentivesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Incentives & offers')),
        body: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 640,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: const [
                _IncentiveCard(
                  title: 'Evening delivery boost',
                  description: 'Complete 5 deliveries between 6 PM and 10 PM.',
                  completed: 2,
                  target: 5,
                  reward: 150,
                ),
                SizedBox(height: AppSpacing.md),
                _IncentiveCard(
                  title: 'Weekly consistency reward',
                  description: 'Stay online for 20 hours this week.',
                  completed: 12,
                  target: 20,
                  reward: 250,
                ),
              ],
            ),
          ),
        ),
      );
}

class _IncentiveCard extends StatelessWidget {
  final String title;
  final String description;
  final int completed;
  final int target;
  final double reward;
  const _IncentiveCard({
    required this.title,
    required this.description,
    required this.completed,
    required this.target,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: '$title. $completed of $target complete. '
            'Reward ${CurrencyFormatter.rupees(reward)}.',
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.h2),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: AppTypography.body),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  child: LinearProgressIndicator(
                    value: completed / target,
                    minHeight: AppSpacing.sm,
                    color: AppColors.secondary,
                    backgroundColor: AppColors.border,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '$completed of $target complete',
                        style: AppTypography.caption,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Earn ${CurrencyFormatter.rupees(reward)}',
                        style: AppTypography.bodyMedium,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
