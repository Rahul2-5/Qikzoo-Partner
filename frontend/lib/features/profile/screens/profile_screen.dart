import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/profile/profile_summary.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';
import '../../../shared/widgets/navigation/app_bottom_nav.dart';
import '../widgets/profile_footer_banner.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_identity_card.dart';
import '../widgets/profile_learning_section.dart';
import '../widgets/profile_menu_tile.dart';
import '../widgets/personal_information_sheet.dart';
import '../widgets/verification_banner.dart';
import '../widgets/wallet_balance_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  ProfileSummary get summary => ProfileSummary.mock();

  void _showComingSoon(BuildContext context, String title) {
    AppSnackBar.info(context, '$title coming soon');
  }

  Future<void> _showPersonalInformation(BuildContext context) async {
    final updated = await PersonalInformationSheet.show(
      context,
      information: mockPersonalInformation,
    );
    if (updated != null && context.mounted) {
      AppSnackBar.success(context, 'Personal information updated');
    }
  }

  Future<void> _logOut(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to access your partner account.',
    );
    if (confirmed == true) Get.offAllNamed(AppRoutes.welcome);
  }

  List<
      ({
        IconData icon,
        String title,
        String subtitle,
        VoidCallback onTap,
        bool destructive
      })> _menuItems(BuildContext context) {
    return [
      (
        icon: LucideIcons.user,
        title: 'Personal Information',
        subtitle: 'Update your personal details',
        onTap: () => _showPersonalInformation(context),
        destructive: false,
      ),
      (
        icon: LucideIcons.landmark,
        title: 'Bank Details',
        subtitle: 'Manage your bank account',
        onTap: () => Get.toNamed(AppRoutes.bankDetails),
        destructive: false,
      ),
      (
        icon: LucideIcons.bike,
        title: 'Vehicle Details',
        subtitle: 'Manage your vehicle information',
        onTap: () => Get.toNamed(AppRoutes.manageVehicleDetails),
        destructive: false,
      ),
      (
        icon: LucideIcons.fileCheck2,
        title: 'Documents',
        subtitle: 'View and manage your documents',
        onTap: () => Get.toNamed(AppRoutes.manageDocuments),
        destructive: false,
      ),
      (
        icon: LucideIcons.badgePercent,
        title: 'Incentives & Offers',
        subtitle: 'View your ongoing offers',
        onTap: () => _showComingSoon(context, 'Incentives & Offers'),
        destructive: false,
      ),
      (
        icon: LucideIcons.lifeBuoy,
        title: 'Help & Support',
        subtitle: 'Get help and raise issues',
        onTap: () => Get.toNamed(AppRoutes.support),
        destructive: false,
      ),
      (
        icon: LucideIcons.settings,
        title: 'Settings',
        subtitle: 'App settings and preferences',
        onTap: () => Get.toNamed(AppRoutes.settings),
        destructive: false,
      ),
      (
        icon: LucideIcons.logOut,
        title: 'Log Out',
        subtitle: 'Log out from your account',
        onTap: () => _logOut(context),
        destructive: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final profile = summary;
    final menuItems = _menuItems(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppStaggeredReveal(
                        index: 0,
                        child: ProfileHeader(
                          notificationCount: profile.notificationCount,
                          onNotifications: () =>
                              Get.toNamed(AppRoutes.notifications),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 1,
                        child: ProfileIdentityCard(
                          summary: profile,
                          onViewStats: () =>
                              _showComingSoon(context, 'View Stats'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 2,
                        child: VerificationBanner(
                          verified: profile.documentsVerified,
                          onTap: () =>
                              Get.toNamed(AppRoutes.verificationStatus),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 3,
                        child: WalletBalanceCard(
                          summary: profile,
                          onWithdraw: () => Get.toNamed(AppRoutes.wallet),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sheet),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < menuItems.length; i++) ...[
                                ProfileMenuTile(
                                  icon: menuItems[i].icon,
                                  title: menuItems[i].title,
                                  subtitle: menuItems[i].subtitle,
                                  onTap: menuItems[i].onTap,
                                  destructive: menuItems[i].destructive,
                                ),
                                if (i < menuItems.length - 1)
                                  const Divider(
                                      height: 1, color: AppColors.border),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const AppStaggeredReveal(
                        index: 5,
                        child: ProfileFooterBanner(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 6,
                        child: ProfileLearningSection(
                          modules: profileLearningModules,
                          onModuleTap: (module) =>
                              _showComingSoon(context, module.title),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              const AppBottomNav(currentIndex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Profile Screen', group: 'Profile', size: Size(390, 844))
Widget profileScreenPreview() => const ProfileScreen();
