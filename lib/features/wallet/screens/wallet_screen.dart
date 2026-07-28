import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helpers/date_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/wallet/transaction_model.dart';
import '../../../models/wallet/wallet_model.dart';
import '../../../providers/wallet/wallet_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Wallet')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletProvider);
          ref.invalidate(transactionsProvider);
          await ref.read(walletProvider.future);
        },
        child: walletAsync.when(
          loading: () => const PageLoadingShimmer(),
          error: (_, __) => _WalletError(onRetry: () => ref.invalidate(walletProvider)),
          data: (wallet) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _WalletBalanceCard(wallet: wallet),
              const SizedBox(height: AppSpacing.md),
              Text('Recent activity', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              transactionsAsync.when(
                loading: () => const SizedBox(
                  height: 250,
                  child: PageLoadingShimmer(showHeader: false, itemCount: 2),
                ),
                error: (_, __) => const EmptyState(message: 'Transactions could not be loaded.'),
                data: (transactions) => transactions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: EmptyState(message: 'No wallet activity yet.'),
                      )
                    : Column(
                        children: [
                          for (final transaction in transactions) ...[
                            _TransactionTile(transaction: transaction),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final WalletModel wallet;
  const _WalletBalanceCard({required this.wallet});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.ctaGradient),
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          boxShadow: AppShadows.cta,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Available balance', style: AppTypography.body.copyWith(color: Colors.white70)),
          const SizedBox(height: AppSpacing.xs),
          Text(CurrencyFormatter.rupeesPrecise(wallet.balance),
              style: AppTypography.numericLg.copyWith(color: Colors.white)),
          const SizedBox(height: AppSpacing.md),
          Text('${CurrencyFormatter.rupeesPrecise(wallet.pendingAmount)} pending in your next payout',
              style: AppTypography.caption.copyWith(color: Colors.white70)),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => AppSnackBar.info(context, 'Withdrawals are included in your scheduled payout.'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
            icon: const Icon(Icons.account_balance_outlined),
            label: const Text('Payout details'),
          ),
        ]),
      );
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final credit = transaction.type == TransactionType.credit;
    final color = credit ? AppColors.secondary : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
      child: Row(children: [
        Icon(credit ? Icons.arrow_downward : Icons.arrow_upward, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(transaction.description, style: AppTypography.bodyMedium),
          Text(DateHelper.formatShort(transaction.date), style: AppTypography.caption),
        ])),
        Text('${credit ? '+' : '-'}${CurrencyFormatter.rupeesPrecise(transaction.amount)}',
            style: AppTypography.bodyMedium.copyWith(color: color)),
      ]),
    );
  }
}

class _WalletError extends StatelessWidget {
  final VoidCallback onRetry;
  const _WalletError({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(onPressed: onRetry, child: const Text('Retry loading wallet')),
      );
}
