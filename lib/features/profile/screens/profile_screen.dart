import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/profile/profile_summary.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../providers/profile/profile_provider.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';
import '../widgets/partner_profile_components.dart';
import '../widgets/personal_information_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _showPartnerId(BuildContext context, WidgetRef ref) async {
    final information = ref.read(personalInformationProvider);
    if (information == null) {
      AppSnackBar.info(context, 'Your details are still loading');
      return;
    }
    await PartnerIdSheet.show(
      context,
      information: information,
    );
  }

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to access your partner account.',
    );
    if (confirmed != true) return;
    await ref.read(authSessionProvider.notifier).logout();
    if (context.mounted) Get.offAllNamed(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(profileSummaryProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTabScaffold(
        currentIndex: 4,
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          child: summaryAsync.when(
            loading: () => const PageLoadingShimmer(
              padding: EdgeInsets.zero,
              itemCount: 3,
            ),
            error: (_, __) => _ProfileErrorState(
              onRetry: () => ref.invalidate(profileProvider),
            ),
            data: (profile) => _buildContent(context, ref, profile),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, ProfileSummary profile) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(profileProvider);
        await ref.read(profileProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PartnerProfileHeader(
              notificationCount: profile.notificationCount,
              onNotifications: () => Get.toNamed(AppRoutes.notifications),
              onProfile: () => _showPartnerId(context, ref),
              partnerName: profile.name,
            ),
            const SizedBox(height: AppSpacing.md),
            PartnerProfileIdentity(
              summary: profile,
              onTap: () => _showPartnerId(context, ref),
            ),
            const SizedBox(height: AppSpacing.md),
            PartnerStoreCard(onTap: () => Get.toNamed(AppRoutes.gigs)),
            const SizedBox(height: 12),
            _ProfileQuickActions(
              children: [
                PartnerQuickAction(
                  icon: LucideIcons.circleDollarSign,
                  title: 'Gigs history',
                  subtitle: 'View past gigs',
                  assetPath: AppAssets.profileGigsHistory3d,
                  iconColor: AppColors.success,
                  onTap: () => Get.toNamed(AppRoutes.gigs),
                ),
                PartnerQuickAction(
                  icon: LucideIcons.bike,
                  title: 'Trips history',
                  subtitle: 'View past trips',
                  assetPath: AppAssets.profileTripsScooter3d,
                  iconColor: AppColors.info,
                  onTap: () => Get.toNamed(AppRoutes.orders),
                ),
                PartnerQuickAction(
                  icon: LucideIcons.ticket,
                  title: 'Your offers',
                  subtitle: 'Active offers',
                  assetPath: AppAssets.profileOffersTicket3d,
                  iconColor: AppColors.secondary,
                  onTap: () => Get.toNamed(AppRoutes.incentives),
                ),
                PartnerQuickAction(
                  icon: LucideIcons.gift,
                  title: 'Your benefits',
                  subtitle: 'See what’s included',
                  assetPath: AppAssets.profileBenefitsGift3d,
                  iconColor: AppColors.accent,
                  onTap: () => Get.toNamed(
                      '${AppRoutes.partnerBenefits}?source=profile'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PartnerProfileMenuGroup(
              children: [
                PartnerProfileMenuTile(
                  grouped: true,
                  icon: LucideIcons.userCheck,
                  title: 'Your fleet coach',
                  subtitle: 'Contact your fleet support team',
                  color: AppColors.success,
                  trailing: const _ProfileActionButton(
                    label: 'Contact',
                    icon: LucideIcons.phone,
                    color: AppColors.success,
                  ),
                  onTap: () => Get.toNamed(AppRoutes.support),
                ),
                PartnerProfileMenuTile(
                  grouped: true,
                  icon: LucideIcons.gift,
                  title: 'Up to ₹7700 referral bonus',
                  subtitle: 'Refer your friend and earn',
                  assetPath: AppAssets.profileBenefitsGift3d,
                  color: AppColors.accent,
                  trailing: const _ProfileActionButton(
                    label: 'Refer & Earn',
                    icon: LucideIcons.chevronRight,
                    color: AppColors.accent,
                  ),
                  onTap: () => Get.toNamed(AppRoutes.incentives),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PartnerProfileMenuGroup(
              children: [
                PartnerProfileMenuTile(
                  grouped: true,
                  icon: LucideIcons.headphones,
                  title: 'Help centre',
                  subtitle: 'Get help and support',
                  assetPath: AppAssets.profileHelpHeadset3d,
                  color: AppColors.info,
                  onTap: () => Get.toNamed(AppRoutes.support),
                ),
                PartnerProfileMenuTile(
                  grouped: true,
                  icon: LucideIcons.ticket,
                  title: 'Support tickets',
                  subtitle: 'View and track your tickets',
                  color: AppColors.secondary,
                  onTap: () => Get.toNamed(AppRoutes.support),
                ),
                PartnerProfileMenuTile(
                  grouped: true,
                  icon: LucideIcons.bike,
                  title: 'Rent an EV',
                  subtitle: 'Rent electric vehicle',
                  assetPath: AppAssets.profileEvScooter3d,
                  color: AppColors.success,
                  onTap: () => Get.toNamed(AppRoutes.manageVehicleDetails),
                ),
                PartnerProfileMenuTile(
                  grouped: true,
                  icon: LucideIcons.fileText,
                  title: 'Agreements',
                  subtitle: 'Terms, privacy & partner policy',
                  color: AppColors.info,
                  onTap: () => Get.toNamed(AppRoutes.agreement),
                ),
                PartnerProfileMenuTile(
                  grouped: true,
                  icon: LucideIcons.settings,
                  title: 'App settings',
                  subtitle: 'Manage app preferences',
                  color: AppColors.textSecondary,
                  onTap: () => Get.toNamed(AppRoutes.settings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _logOut(context, ref),
              icon: const Icon(LucideIcons.logOut, size: 21),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.info),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Qikzoo Partner App',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'Version 2.4.1',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDisabled,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 126),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 7),
                Text(label,
                    style: AppTypography.bodyMedium.copyWith(color: color)),
              ],
            ),
          ),
        ),
      );
}

/// Uses two columns on phones so every quick action has enough room for its
/// illustration and two-line label, without shrinking the touch target.
class _ProfileQuickActions extends StatelessWidget {
  const _ProfileQuickActions({required this.children});

  final List<PartnerQuickAction> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          // Three compact cards retain useful text width on a 520dp frame;
          // four columns made each action feel tall and cramped.
          final columns = constraints.maxWidth >= 480 ? 3 : 2;
          final itemWidth =
              (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns;

          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final action in children)
                SizedBox(width: itemWidth, child: action),
            ],
          );
        },
      );
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.userX,
                size: 44, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text("We couldn't load your profile",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            const Text('Please check your connection and try again.',
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'Profile Screen', group: 'Profile', size: Size(390, 844))
@Preview(
  name: 'Profile Screen - Compact',
  group: 'Profile',
  size: Size(320, 844),
)
@Preview(name: 'Profile Screen — Wide', group: 'Profile', size: Size(640, 844))
Widget profileScreenPreview() =>
    const ProviderScope(child: MaterialApp(home: ProfileScreen()));
