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
            PartnerProfileHeader(onBack: Get.back),
            const SizedBox(height: AppSpacing.xs),
            PartnerProfileIdentity(
              summary: profile,
              onTap: () => _showPartnerId(context, ref),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PartnerQuickAction(
                    icon: LucideIcons.circleDollarSign,
                    title: 'Gigs history',
                    onTap: () => Get.toNamed(AppRoutes.gigs),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PartnerQuickAction(
                    icon: LucideIcons.bike,
                    title: 'Trips history',
                    onTap: () => Get.toNamed(AppRoutes.orders),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PartnerReferralCard(
              onTap: () => Get.toNamed(AppRoutes.incentives),
            ),
            const SizedBox(height: AppSpacing.md),
            PartnerProfileSection(
              title: 'Support',
              items: [
                PartnerProfileSectionItem(
                  icon: LucideIcons.headphones,
                  title: 'Help centre',
                  onTap: () => Get.toNamed(AppRoutes.support),
                ),
                PartnerProfileSectionItem(
                  icon: LucideIcons.ticket,
                  title: 'Support tickets',
                  onTap: () => Get.toNamed(AppRoutes.support),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PartnerProfileSection(
              title: 'Partner options',
              items: [
                PartnerProfileSectionItem(
                  icon: LucideIcons.car,
                  title: 'Rest points',
                  onTap: () => Get.toNamed(AppRoutes.manageVehicleDetails),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PartnerProfileSection(
              title: 'Your benefits',
              items: [
                PartnerProfileSectionItem(
                  icon: LucideIcons.stethoscope,
                  title: 'Doctor visit at store',
                  onTap: () => Get.toNamed(
                    '${AppRoutes.partnerBenefits}?source=profile',
                  ),
                ),
                PartnerProfileSectionItem(
                  icon: LucideIcons.heartPulse,
                  title: 'Medical insurance',
                  onTap: () => Get.toNamed(
                    '${AppRoutes.partnerBenefits}?source=profile',
                  ),
                ),
                PartnerProfileSectionItem(
                  icon: LucideIcons.gift,
                  title: 'Scratch cards',
                  onTap: () => Get.toNamed(AppRoutes.incentives),
                ),
                PartnerProfileSectionItem(
                  icon: LucideIcons.fileText,
                  title: 'Agreement',
                  onTap: () => Get.toNamed(AppRoutes.agreement),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PartnerProfileSection(
              title: 'App settings',
              items: [
                PartnerProfileSectionItem(
                  icon: LucideIcons.languages,
                  title: 'App language',
                  onTap: () => Get.toNamed(AppRoutes.settings),
                ),
                PartnerProfileSectionItem(
                  icon: LucideIcons.music,
                  title: 'Audio language',
                  onTap: () => Get.toNamed(AppRoutes.settings),
                ),
                PartnerProfileSectionItem(
                  icon: LucideIcons.helpCircle,
                  title: 'Support language',
                  onTap: () => Get.toNamed(AppRoutes.settings),
                ),
                PartnerProfileSectionItem(
                  icon: LucideIcons.bell,
                  title: 'Order alert sound',
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
                minimumSize: const Size.fromHeight(56),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Qikzoo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Text(
              'PARTNER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
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
