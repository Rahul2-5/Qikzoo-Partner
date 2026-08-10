import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/empty_state.dart';

/// No incentive-campaign backend exists yet — this screen deliberately shows
/// an honest empty state rather than fabricated campaigns/progress/rewards.
class IncentivesScreen extends StatelessWidget {
  const IncentivesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Incentives & offers')),
        body: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 640,
            child: const EmptyState(
              icon: LucideIcons.gift,
              title: 'No active incentives',
              message:
                  "You'll see bonus campaigns here as soon as they're available in your zone.",
            ),
          ),
        ),
      );
}
