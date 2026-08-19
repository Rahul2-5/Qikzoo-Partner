import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/profile/profile_summary.dart';
import '../../../providers/profile/profile_provider.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTabScaffold(
        currentIndex: 4,
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: EdgeInsets.zero,
          child: profileAsync.when(
            loading: () => const ProfileLoadingShimmer(),
            error: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'We could not load your profile. Please try again.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
              ),
            ),
            data: (profile) => _MoreBody(profile: profile),
          ),
        ),
      ),
    );
  }
}

class _MoreBody extends StatelessWidget {
  const _MoreBody({required this.profile});

  final ProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHero(profile: profile),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MenuSection(
                  title: 'Account',
                  children: [
                    _MenuRow(
                      icon: LucideIcons.user,
                      iconColor: AppColors.primary,
                      title: 'My profile',
                      subtitle: 'Personal details, documents and vehicle',
                      onTap: () => Get.toNamed(AppRoutes.myProfile),
                    ),
                    _MenuRow(
                      icon: LucideIcons.headphones,
                      iconColor: AppColors.secondary,
                      title: 'Help & support',
                      subtitle: 'FAQs, live chat and delivery help',
                      onTap: () => Get.toNamed(AppRoutes.ticketList),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _MenuSection(
                  title: 'Partner tools',
                  children: [
                    _MenuRow(
                      icon: LucideIcons.gift,
                      iconColor: AppColors.success,
                      title: 'Refer & earn',
                      subtitle: 'Invite partners and earn rewards',
                      badgeText: '\u{20B9}100',
                      onTap: () => Get.toNamed(AppRoutes.incentives),
                    ),
                    _MenuRow(
                      icon: LucideIcons.bell,
                      iconColor: const Color(0xFF7C3AED),
                      title: 'Notifications',
                      subtitle: 'Order and account updates',
                      onTap: () => Get.toNamed(AppRoutes.notifications),
                    ),
                    _MenuRow(
                      icon: LucideIcons.shieldAlert,
                      iconColor: AppColors.warning,
                      title: 'Wrong action',
                      subtitle: 'Review activity and safety guidance',
                      onTap: () => Get.toNamed(AppRoutes.wrongAction),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _MenuSection(
                  title: 'Preferences',
                  children: [
                    _MenuRow(
                      icon: LucideIcons.history,
                      iconColor: AppColors.textSecondary,
                      title: 'Login history',
                      subtitle: 'Review recent account access',
                      onTap: () => Get.toNamed(AppRoutes.loginHistory),
                    ),
                    _MenuRow(
                      icon: LucideIcons.fileText,
                      iconColor: AppColors.textSecondary,
                      title: 'Legal',
                      subtitle: 'Terms, policies and partner agreement',
                      onTap: () => Get.toNamed(AppRoutes.agreement),
                    ),
                    _MenuRow(
                      icon: LucideIcons.settings,
                      iconColor: AppColors.textSecondary,
                      title: 'Settings',
                      subtitle: 'App and communication preferences',
                      onTap: () => Get.toNamed(AppRoutes.settings),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Qikzoo Partner \u{2022} Version 0.3.2',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});

  final ProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    final displayName =
        profile.name.trim().isEmpty ? 'Qikzoo partner' : profile.name.trim();
    final partnerId = profile.partnerId.trim().isEmpty
        ? 'ID unavailable'
        : profile.partnerId.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primarySoft,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.sheet),
        ),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              softWrap: true,
              style: AppTypography.h1.copyWith(
                fontSize: 22,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Partner ID \u{2022} $partnerId',
              softWrap: true,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _ProfileChip(
                  icon: LucideIcons.star,
                  label: profile.ratingAverage > 0
                      ? profile.ratingAverage.toStringAsFixed(1)
                      : 'New partner',
                ),
                _ProfileChip(
                  icon: LucideIcons.packageCheck,
                  label: profile.deliveriesLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.secondary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                softWrap: true,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(
              title.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  children[index],
                  if (index != children.length - 1)
                    const Divider(
                      height: 1,
                      indent: 64,
                      endIndent: AppSpacing.md,
                      color: AppColors.border,
                    ),
                ],
              ],
            ),
          ),
        ],
      );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeText,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 19, color: iconColor),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: 4,
                        children: [
                          Text(
                            title,
                            softWrap: true,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (badgeText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                badgeText!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        softWrap: true,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.textDisabled,
                ),
              ],
            ),
          ),
        ),
      );
}
