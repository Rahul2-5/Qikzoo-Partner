import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/profile/partner_profile_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../providers/profile/profile_provider.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
    final profileAsync = ref.watch(profileProvider);
    final ratingAsync = ref.watch(ratingProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: profileAsync.when(
            loading: () => const ProfileLoadingShimmer(),
            error: (_, __) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.userX, size: 44, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text('Failed to load profile details'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(profileProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (profile) => _buildProfileBody(
              context,
              ref,
              profile,
              ratingAsync.valueOrNull?.average,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileBody(
    BuildContext context,
    WidgetRef ref,
    PartnerProfileModel profile,
    double? rating,
  ) {
    final joinedDateStr = DateFormat('dd/MM/yyyy').format(profile.joinedDate);
    final publicId = profile.publicRiderId ??
        (profile.id.isNotEmpty
            ? profile.id.substring(0, profile.id.length.clamp(0, 8))
            : '34174427');

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(profileProvider);
        ref.invalidate(ratingProvider);
        await Future.wait([
          ref.read(profileProvider.future),
          ref.read(ratingProvider.future),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 22),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(width: 8),
                Text(
                  'Profile',
                  style: AppTypography.h1.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Avatar & Ratings Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  ),
                  child: ClipOval(
                    child: profile.selfieUrl != null && profile.selfieUrl!.isNotEmpty
                        ? Image.network(
                            profile.selfieUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/icons/user.webp',
                              fit: BoxFit.cover,
                            ),
                          )
                        : (profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                            ? Image.network(
                                profile.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/icons/user.webp',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'assets/icons/user.webp',
                                fit: BoxFit.cover,
                              )),
                  ),
                ),
                const SizedBox(width: 24),
                // Your ratings
                InkWell(
                  onTap: () => Get.toNamed(AppRoutes.support),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Your ratings',
                              style: TextStyle(
                                color: Color(0xFF4B5563),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF4B5563)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.star, color: Color(0xFFFACC15), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              rating != null && rating > 0 ? rating.toStringAsFixed(1) : '-',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Name & DE ID
            Text(
              profile.name.isNotEmpty ? profile.name : 'Partner Name',
              style: AppTypography.h1.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'DE ID: $publicId',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEEEEEE), height: 1, thickness: 1),
            const SizedBox(height: 16),

            // 2x2 Details Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Col 1: Mobile number
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Mobile\nnumber',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                              height: 1.15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.myProfile),
                            child: const Icon(
                              LucideIcons.edit,
                              size: 15,
                              color: Color(0xFF0D8538),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.phone.isNotEmpty ? profile.phone : '9987244539',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                // Col 2: Joining date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Joining date',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        joinedDateStr.isNotEmpty ? joinedDateStr : '28/07/2026',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Col 1: City
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'City',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.city ?? 'Mumbai',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                // Col 2: Order Category
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order\nCategory',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                          height: 1.15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Food',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEEEEEE), height: 1, thickness: 1),
            const SizedBox(height: 8),

            // Menu Items List
            _ProfileDetailMenuItem(
              iconWidget: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.fileBadge, color: Color(0xFF475569), size: 22),
              ),
              title: 'Your documents',
              onTap: () => Get.toNamed(AppRoutes.manageDocuments),
            ),
            const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1),

            _ProfileDetailMenuItem(
              iconWidget: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(LucideIcons.plusCircle, color: Color(0xFFDC2626), size: 22),
                ),
              ),
              title: 'Emergency details',
              onTap: () => Get.toNamed(AppRoutes.emergencySos),
            ),
            const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1),

            _ProfileDetailMenuItem(
              iconWidget: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.landmark, color: Color(0xFF475569), size: 22),
              ),
              title: 'Bank details',
              onTap: () => Get.toNamed(AppRoutes.bankDetails),
            ),
            const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1),

            _ProfileDetailMenuItem(
              iconWidget: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.languages, color: Color(0xFF0D8538), size: 22),
              ),
              title: 'App language',
              subtitle: 'English',
              onTap: () {
                Get.rawSnackbar(
                  message: 'Selected language: English',
                  duration: const Duration(seconds: 2),
                );
              },
            ),
            const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1),

            _ProfileDetailMenuItem(
              iconWidget: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.fileText, color: Color(0xFF475569), size: 22),
              ),
              title: 'Terms & Agreements',
              onTap: () => Get.toNamed(AppRoutes.agreement),
            ),
            const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1),

            _ProfileDetailMenuItem(
              iconWidget: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.headphones, color: Color(0xFF475569), size: 22),
              ),
              title: 'Help & Support',
              onTap: () => Get.toNamed(AppRoutes.support),
            ),
            const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1),

            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _logOut(context, ref),
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Qikzoo Partner • Version 2.4.1',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailMenuItem extends StatelessWidget {
  const _ProfileDetailMenuItem({
    required this.iconWidget,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final Widget iconWidget;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.chevronRight,
                color: Color(0xFF10B981),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
