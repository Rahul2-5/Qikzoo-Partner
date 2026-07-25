import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/app_bottom_nav.dart';
import '../widgets/available_gigs_section.dart';

class GigsScreen extends StatelessWidget {
  const GigsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
            maxWidth: 640,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Column(children: [
              Expanded(
                  child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                    Text('Gigs', style: AppTypography.h1),
                    const SizedBox(height: 2),
                    Text('Pick a delivery shift that works for you.',
                        style: AppTypography.body
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                            color: AppColors.secondaryBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.control)),
                        child: Row(children: [
                          const Icon(LucideIcons.checkCircle2,
                              size: 18, color: AppColors.secondary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                              child: Text(
                                  'Book a gig to secure guaranteed earnings for your shift.',
                                  style: AppTypography.caption
                                      .copyWith(color: AppColors.textPrimary)))
                        ])),
                    const SizedBox(height: AppSpacing.lg),
                    const AvailableGigsSection(showAll: true),
                  ])),
              const AppBottomNav(currentIndex: 1),
            ])),
      ));
}

@Preview(name: 'Gigs screen', group: 'Gigs', size: Size(390, 844))
Widget gigsScreenPreview() => const MaterialApp(home: GigsScreen());
