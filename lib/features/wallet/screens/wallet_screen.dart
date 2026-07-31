import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';

/// A pocket-style overview of the partner's available wallet funds.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pocket'),
        actions: [
          IconButton(
            tooltip: 'Wallet help',
            onPressed: () => AppSnackBar.info(
                context, 'Wallet help will be available soon.'),
            icon: const Icon(LucideIcons.helpCircle),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 640,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(walletProvider);
              ref.invalidate(transactionsProvider);
              await ref.read(walletProvider.future);
            },
            child: walletAsync.when(
              loading: () => const PageLoadingShimmer(),
              error: (_, __) => _WalletError(
                onRetry: () => ref.invalidate(walletProvider),
              ),
              data: (wallet) => _PocketContent(
                wallet: wallet,
                transactionsAsync: transactionsAsync,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PocketContent extends StatelessWidget {
  const _PocketContent({required this.wallet, required this.transactionsAsync});

  final WalletModel wallet;
  final AsyncValue<List<TransactionModel>> transactionsAsync;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xxl,
      ),
      children: [
        _EarningsSummary(amount: wallet.balance),
        const SizedBox(height: AppSpacing.xl),
        const _SectionLabel('POCKET'),
        const SizedBox(height: AppSpacing.sm),
        _PocketBalanceCard(wallet: wallet),
        const SizedBox(height: AppSpacing.md),
        transactionsAsync.when(
          loading: () => const SizedBox(
            height: 84,
            child: PageLoadingShimmer(showHeader: false, itemCount: 1),
          ),
          error: (_, __) => const _CompactStatusCard(
            icon: LucideIcons.receipt,
            title: 'Activity is temporarily unavailable',
            subtitle: 'Pull down to try again.',
          ),
          data: (transactions) => transactions.isEmpty
              ? const _CompactStatusCard(
                  icon: LucideIcons.receipt,
                  title: 'No pocket activity yet',
                  subtitle: 'Your payouts and adjustments will appear here.',
                )
              : _ActivityCard(transaction: transactions.first),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionLabel('MORE SERVICES'),
        const SizedBox(height: AppSpacing.sm),
        const _ServicesGrid(),
      ],
    );
  }
}

class _EarningsSummary extends StatelessWidget {
  const _EarningsSummary({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final period =
        '${DateHelper.formatShort(weekStart)} - ${DateHelper.formatShort(weekEnd)}';

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Text('Available balance', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(period, style: AppTypography.caption),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.rupeesPrecise(amount),
              style: AppTypography.display.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PocketBalanceCard extends StatelessWidget {
  const _PocketBalanceCard({required this.wallet});

  final WalletModel wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _BalanceLine(
            label: 'Pocket balance',
            amount: CurrencyFormatter.rupeesPrecise(wallet.balance),
            onTap: () => AppSnackBar.info(
                context, 'Your available balance is ready for payout.'),
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.border),
          _BalanceLine(
            label: 'Pending payout',
            amount: CurrencyFormatter.rupeesPrecise(wallet.pendingAmount),
            onTap: () => AppSnackBar.info(
                context, 'Pending funds are included in your next payout.'),
          ),
          const SizedBox(height: AppSpacing.md),
          _WalletActions(wallet: wallet),
        ],
      ),
    );
  }
}

class _WalletActions extends StatelessWidget {
  const _WalletActions({required this.wallet});

  final WalletModel wallet;

  @override
  Widget build(BuildContext context) {
    final addFundsButton = OutlinedButton(
      onPressed: () => AppSnackBar.info(
        context,
        'Adding money to your pocket will be available soon.',
      ),
      child: const Text('Add funds'),
    );
    final withdrawButton = FilledButton(
      onPressed: wallet.balance > 0
          ? () => AppSnackBar.info(
                context,
                'Withdrawals are included in your scheduled payout.',
              )
          : null,
      child: const Text('Withdraw'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackButtons = constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        if (stackButtons) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              addFundsButton,
              const SizedBox(height: AppSpacing.sm),
              withdrawButton,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: addFundsButton),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: withdrawButton),
          ],
        );
      },
    );
  }
}

class _BalanceLine extends StatelessWidget {
  const _BalanceLine(
      {required this.label, required this.amount, required this.onTap});

  final String label;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.control),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTypography.bodyMedium)),
            Flexible(
              child: Text(
                amount,
                style: AppTypography.numericMd,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(LucideIcons.chevronRight, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final amount = CurrencyFormatter.rupeesPrecise(transaction.amount);
    return _TappableCard(
      onTap: () => AppSnackBar.info(
          context, 'Transaction details will be available soon.'),
      child: Row(
        children: [
          _CircleIcon(
            icon:
                isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
            color: isCredit ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description, style: AppTypography.bodyMedium),
                const SizedBox(height: 2),
                Text(DateHelper.formatShort(transaction.date),
                    style: AppTypography.caption),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}$amount',
            style: AppTypography.bodyMedium.copyWith(
                color: isCredit ? AppColors.success : AppColors.error),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(LucideIcons.chevronRight, size: 20),
        ],
      ),
    );
  }
}

class _CompactStatusCard extends StatelessWidget {
  const _CompactStatusCard(
      {required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => _TappableCard(
        onTap: () {},
        child: Row(
          children: [
            _CircleIcon(icon: icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid();

  @override
  Widget build(BuildContext context) {
    const services = [
      _ServiceData('Payout history', LucideIcons.walletCards),
      _ServiceData('Pocket statement', LucideIcons.fileText),
      _ServiceData('Deductions', LucideIcons.indianRupee),
      _ServiceData('Earnings report', LucideIcons.barChart3),
      _ServiceData('Partner rewards', LucideIcons.gift),
      _ServiceData('Payment support', LucideIcons.headphones),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: constraints.maxWidth < 360 ? 180 : 210,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisExtent: 132,
        ),
        itemBuilder: (context, index) {
          final service = services[index];
          return _TappableCard(
            onTap: () => AppSnackBar.info(
              context,
              '${service.label} will be available soon.',
            ),
            height: 132,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CircleIcon(icon: service.icon, color: AppColors.primary),
                const Spacer(),
                Text(
                  service.label,
                  style: AppTypography.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ServiceData {
  const _ServiceData(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      );
}

class _TappableCard extends StatelessWidget {
  const _TappableCard(
      {required this.child, required this.onTap, this.height = 84});

  final Widget child;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Ink(
            height: height,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.card,
            ),
            child: child,
          ),
        ),
      );
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: color),
      );
}

class _WalletError extends StatelessWidget {
  const _WalletError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(
            onPressed: onRetry, child: const Text('Retry loading wallet')),
      );
}
