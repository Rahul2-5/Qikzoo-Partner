import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';

class IncentivesScreen extends StatelessWidget {
  const IncentivesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String referralCode = 'QIKPARTNER7700';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Get.back(),
              )
            : null,
      ),
      body: ResponsiveFrame(
        maxWidth: 520,
        padding: const EdgeInsets.all(AppSpacing.md),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Highlight Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.gift, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Earn up to ₹7,700',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'For every delivery partner you refer to Qikzoo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Sharing Card (Referral code + Buttons)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'YOUR REFERRAL CODE',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              referralCode,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(const ClipboardData(text: referralCode));
                                AppSnackBar.success(context, 'Referral code copied to clipboard.');
                              },
                              child: const Row(
                                children: [
                                  Icon(LucideIcons.copy, size: 16, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text(
                                    'COPY',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            AppSnackBar.info(context, 'Referral link: get.qikzoo.com/partner/ref=$referralCode');
                          },
                          icon: const Icon(LucideIcons.share2, color: Colors.white, size: 16),
                          label: const Text('Share Link with Friends'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // How it works
                Text(
                  'How it works',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),

                _buildStepItem(
                  stepNum: '1',
                  title: 'Send Invite Link',
                  desc: 'Share your unique referral link/code with your friends.',
                ),
                const SizedBox(height: 12),
                _buildStepItem(
                  stepNum: '2',
                  title: 'Friend Registers',
                  desc: 'Your friend registers, uploads documents, and gets approved.',
                ),
                const SizedBox(height: 12),
                _buildStepItem(
                  stepNum: '3',
                  title: 'Deliver & Earn',
                  desc: 'Once your friend completes their first 15 deliveries in 15 days, you receive ₹7,700!',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildStepItem({
    required String stepNum,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              stepNum,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
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
