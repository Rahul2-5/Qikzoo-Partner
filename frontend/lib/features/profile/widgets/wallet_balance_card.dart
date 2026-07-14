import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/profile/profile_summary.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';

class WalletBalanceCard extends StatelessWidget {
  final ProfileSummary summary;
  final VoidCallback onWithdraw;

  const WalletBalanceCard({
    super.key,
    required this.summary,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primarySoft, Color(0xFFDDF5EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        boxShadow: AppShadows.control,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wallet Balance', style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                      CurrencyFormatter.rupeesPrecise(summary.walletBalance),
                      style: AppTypography.numericLg),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('${summary.bankName} ····${summary.maskedAccount}',
                    style: AppTypography.caption),
                const SizedBox(height: 2),
                Text('Next payout: ${summary.nextPayoutDate}',
                    style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PrimaryCtaButton(
            label: 'Withdraw',
            fullWidth: false,
            trailingIcon: LucideIcons.arrowUpRight,
            onPressed: onWithdraw,
          ),
        ],
      ),
    );
  }
}
