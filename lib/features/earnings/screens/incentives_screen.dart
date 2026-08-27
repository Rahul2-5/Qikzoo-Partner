import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/referrals/referral_summary_model.dart';
import '../../../providers/referrals/referral_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';

class IncentivesScreen extends ConsumerWidget {
  const IncentivesScreen({super.key});
  static const _inviteBase = 'https://qikzoo.com/partner/invite';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      body: SafeArea(
        child: ref.watch(referralSummaryProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(referralSummaryProvider),
                  child: const Text('Try again'),
                ),
              ),
              data: (summary) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: Get.back,
                          icon: const Icon(LucideIcons.arrowLeft),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _showTerms(context),
                          icon: const Icon(LucideIcons.helpCircle),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                      children: [
                        Text(
                          'Refer & Earn',
                          textAlign: TextAlign.center,
                          style: AppTypography.h1.copyWith(fontSize: 30),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'The more you share, the more you earn',
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Image.asset(
                          AppAssets.referralPartners3d,
                          height: 218,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        _rewards(summary),
                        const SizedBox(height: 20),
                        _codeCard(context, summary.referralCode),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _share(context, summary.referralCode),
                        icon: const Icon(LucideIcons.messageCircle, size: 21),
                        label: const Text('Invite on WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: AppTypography.button,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _rewards(ReferralSummaryModel summary) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _rewardCard(
              icon: LucideIcons.wallet,
              color: AppColors.success,
              tint: const Color(0xFFE7F7EE),
              heading: 'You get',
              value: '200',
              footnote: 'per successful referral',
            ),
            const SizedBox(width: 12),
            _rewardCard(
              icon: summary.isUnlocked
                  ? LucideIcons.badgeCheck
                  : LucideIcons.lock,
              color: const Color(0xFFE86D32),
              tint: const Color(0xFFFFE9DE),
              heading: summary.isUnlocked ? 'Unlocked' : 'Withdraw after',
              value: summary.isUnlocked ? 'Ready' : '10 orders',
              footnote: summary.isUnlocked
                  ? 'reward available'
                  : 'successful deliveries',
            ),
          ],
        ),
      );

  Widget _rewardCard({
    required IconData icon,
    required Color color,
    required Color tint,
    required String heading,
    required String value,
    required String footnote,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .045),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Icon(icon, size: 19, color: color),
              ),
              const Spacer(),
              Text(heading, style: AppTypography.caption),
              const SizedBox(height: 2),
              Text(value, style: AppTypography.h2.copyWith(color: color)),
              const SizedBox(height: 2),
              Text(footnote, style: AppTypography.caption),
            ],
          ),
        ),
      );

  Widget _codeCard(BuildContext context, String code) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1DDD0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9DE),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.gift, color: Color(0xFFE86D32)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR REFERRAL CODE', style: AppTypography.caption),
                  const SizedBox(height: 2),
                  Text(code,
                      style: AppTypography.h2.copyWith(letterSpacing: .8)),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  AppSnackBar.success(context, 'Referral code copied');
                }
              },
              icon: const Icon(LucideIcons.copy, color: AppColors.primary),
            ),
          ],
        ),
      );

  Future<void> _share(BuildContext context, String code) async {
    final link = '$_inviteBase?ref=$code';
    await Share.share(
      'Join Qikzoo Partner and start delivering with me!\n\nInstall or open the app using my invite: $link',
      subject: 'Join Qikzoo Partner',
    );
  }

  void _showTerms(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: .62,
        minChildSize: .35,
        maxChildSize: .88,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: const [
            Text('Referral terms'),
            SizedBox(height: 16),
            _Term(
                'Share your personal invite link with a new delivery partner.'),
            _Term(
                'They are linked to you automatically when they install or open the app and sign in.'),
            _Term(
                'When they complete 10 successful deliveries, \u{20B9}200 is credited to your wallet.'),
            _Term(
                'Once credited, the reward is available for withdrawal under normal KYC and payout rules.'),
            _Term('One reward is allowed for each new partner.'),
          ],
        ),
      ),
    );
  }
}

class _Term extends StatelessWidget {
  const _Term(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(LucideIcons.checkCircle2,
            size: 18, color: AppColors.success),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTypography.body))
      ]));
}
