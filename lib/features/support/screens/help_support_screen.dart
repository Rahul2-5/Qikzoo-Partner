import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../profile/widgets/account_screen_components.dart';

/// There is no support-ticketing backend yet — this screen deliberately
/// does not fabricate tickets or pretend "Call us"/"Live chat" connect to
/// anything real. FAQs below are static help copy, not business data.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _showComingSoon(BuildContext context, String channel) {
    AppSnackBar.info(context, '$channel support is not available yet.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AccountScreenHeader(
                title: 'Help & Support',
                subtitle:
                    'Get quick help with deliveries, payouts, or your account.',
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.sheet),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.headphones,
                                color: Colors.white,
                                size: 27,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'How can we help?',
                              style: AppTypography.h2
                                  .copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Browse frequently asked questions below',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: _SupportChannelButton(
                                    icon: LucideIcons.phone,
                                    label: 'Call us',
                                    onTap: () async {
                                      final uri = Uri.parse('tel:1800123456');
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      } else if (context.mounted) {
                                        _showComingSoon(context, 'Phone');
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _SupportChannelButton(
                                    icon: LucideIcons.messageCircle,
                                    label: 'Live chat',
                                    onTap: () => Get.toNamed(
                                      AppRoutes.ticketChat,
                                      arguments: {
                                        'id': 'TCK-LIVE',
                                        'title': 'Live Support Assistant',
                                        'status': 'Open',
                                        'outlet': 'Qikzoo Partner Care',
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Frequently asked questions',
                          style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      const AccountSectionCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _FaqTile(
                              question: 'When will I receive my payout?',
                              answer:
                                  'Completed delivery earnings are included in your next scheduled payout after verification.',
                            ),
                            Divider(height: 1),
                            _FaqTile(
                              question: 'How do I update a document?',
                              answer:
                                  'Open Documents from your profile, select the document, and choose Replace.',
                            ),
                            Divider(height: 1),
                            _FaqTile(
                              question: 'What if an order has an issue?',
                              answer:
                                  'Use call or chat support from the active order screen for the fastest assistance.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportChannelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SupportChannelButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        title: Text(question, style: AppTypography.bodyMedium),
        iconColor: AppColors.secondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(answer, style: AppTypography.body),
          ),
        ],
      ),
    );
  }
}
