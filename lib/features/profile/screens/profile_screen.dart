import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/profile/profile_summary.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../providers/profile/profile_provider.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
import '../../../shared/widgets/navigation/app_bottom_nav.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
            const AppBottomNav(currentIndex: 4),
          ],
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
            ),
            const SizedBox(height: AppSpacing.lg),
            PartnerProfileIdentity(
              summary: profile,
              onTap: () => _showPartnerId(context, ref),
            ),
            const SizedBox(height: AppSpacing.lg),
            PartnerStoreCard(onTap: () => Get.toNamed(AppRoutes.gigs)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PartnerQuickAction(
                    icon: LucideIcons.circleDollarSign,
                    title: 'Gigs history',
                    iconColor: const Color(0xFF1AA440),
                    onTap: () => Get.toNamed(AppRoutes.gigs),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PartnerQuickAction(
                    icon: LucideIcons.bike,
                    title: 'Trips history',
                    iconColor: const Color(0xFF2766DB),
                    onTap: () => Get.toNamed(AppRoutes.orders),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PartnerQuickAction(
                    icon: LucideIcons.ticket,
                    title: 'Your offers',
                    iconColor: const Color(0xFF8035B9),
                    onTap: () => Get.toNamed(AppRoutes.incentives),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PartnerProfileMenuTile(
              icon: LucideIcons.userCheck,
              title: 'Your fleet coach',
              subtitle: 'Contact your fleet support team',
              color: const Color(0xFF17A84A),
              trailing: Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3FBF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: PartnerProfileColors.border),
                ),
                child: const Icon(LucideIcons.phone,
                    color: Color(0xFF17A84A), size: 21),
              ),
              onTap: () => Get.toNamed(AppRoutes.support),
            ),
            const SizedBox(height: AppSpacing.sm),
            PartnerProfileMenuTile(
              icon: LucideIcons.gift,
              title: 'Up to ₹7700 referral bonus',
              subtitle: 'Refer your friend and earn',
              color: const Color(0xFFF59B18),
              onTap: () => Get.toNamed(AppRoutes.incentives),
            ),
            const SizedBox(height: AppSpacing.sm),
            PartnerProfileMenuTile(
              icon: LucideIcons.headphones,
              title: 'Help centre',
              color: const Color(0xFF2766DB),
              onTap: () => Get.toNamed(AppRoutes.support),
            ),
            const SizedBox(height: AppSpacing.sm),
            PartnerProfileMenuTile(
              icon: LucideIcons.ticket,
              title: 'Support tickets',
              color: AppColors.textPrimary,
              onTap: () => Get.toNamed(AppRoutes.support),
            ),
            const SizedBox(height: AppSpacing.sm),
            PartnerProfileMenuTile(
              icon: LucideIcons.bike,
              title: 'Rent an EV',
              color: const Color(0xFF8035B9),
              onTap: () => Get.toNamed(AppRoutes.manageVehicleDetails),
            ),
            const SizedBox(height: AppSpacing.sm),
            PartnerProfileMenuTile(
              icon: LucideIcons.gift,
              title: 'Your benefits',
              color: const Color(0xFFD34669),
              onTap: () =>
                  Get.toNamed('${AppRoutes.partnerBenefits}?source=profile'),
            ),
            const SizedBox(height: AppSpacing.sm),
            PartnerProfileMenuTile(
              icon: LucideIcons.settings,
              title: 'App settings',
              color: AppColors.textSecondary,
              onTap: () => Get.toNamed(AppRoutes.settings),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _logOut(context, ref),
              icon: const Icon(LucideIcons.logOut, size: 21),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.info),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
Widget profileScreenPreview() =>
    const ProviderScope(child: MaterialApp(home: ProfileScreen()));
