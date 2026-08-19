import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/wallet/wallet_model.dart';
import '../../../providers/wallet/wallet_provider.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
import '../widgets/deposit_cash_sheet.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          LucideIcons.arrowLeft,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                        onPressed: () => Get.back(),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Wallet',
                        style: AppTypography.h1.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.helpCircle, color: Color(0xFF6B7280), size: 20),
                    onPressed: () => Get.toNamed(AppRoutes.support),
                    tooltip: 'Payment Support',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Main Scrollable Area
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(walletProvider);
                    ref.invalidate(transactionsProvider);
                    await Future.wait([
                      ref.read(walletProvider.future),
                      ref.read(transactionsProvider.future),
                    ]);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: walletAsync.when(
                      loading: () => const WalletLoadingShimmer(),
                      error: (_, __) => _buildWalletContent(
                        context,
                        ref,
                        const WalletModel(
                          balance: 0,
                          pendingAmount: 0,
                        ),
                        transactionsAsync,
                      ),
                      data: (wallet) => _buildWalletContent(
                        context,
                        ref,
                        wallet,
                        transactionsAsync,
                      ),
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

  Widget _buildWalletContent(
    BuildContext context,
    WidgetRef ref,
    WalletModel wallet,
    AsyncValue transactionsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total Wallet Balance Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL WALLET BALANCE',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.rupeesPrecise(wallet.balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'PlusJakartaSans',
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pending Settlement',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.rupeesPrecise(wallet.pendingAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.payoutsDetail),
                    icon: const Icon(LucideIcons.arrowUpRight, size: 16),
                    label: const Text('View Payouts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Floating Cash (COD) Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        AppAssets.profileEarningsWallet3d,
                        width: 30,
                        height: 30,
                        errorBuilder: (_, __, ___) => const Icon(
                          LucideIcons.banknote,
                          color: Color(0xFF0D8538),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Floating Cash (COD)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cash in hand: ${CurrencyFormatter.rupeesPrecise(wallet.floatingCash)}  •  Limit: ${CurrencyFormatter.rupeesPrecise(wallet.cashLimit)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Get.toNamed(AppRoutes.payoutsDetail),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Details & Limits',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          DepositCashSheet.show(
                            context,
                            currentCashInHand: wallet.floatingCash,
                            onDepositSuccess: () => ref.invalidate(walletProvider),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D8538),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Deposit Cash',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick Services Grid
        const Text(
          'Quick Services',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickServiceTile(
                assetPath: AppAssets.profileEarningsWallet3d,
                fallbackIcon: LucideIcons.landmark,
                title: 'Bank Details',
                onTap: () => Get.toNamed(AppRoutes.bankDetails),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickServiceTile(
                assetPath: AppAssets.dashboardIncentives3d,
                fallbackIcon: LucideIcons.receipt,
                title: 'Payouts',
                onTap: () => Get.toNamed(AppRoutes.payoutsDetail),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickServiceTile(
                assetPath: AppAssets.profileOffersTicket3d,
                fallbackIcon: LucideIcons.gift,
                title: 'Incentives',
                onTap: () => Get.toNamed(AppRoutes.incentives),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickServiceTile(
                assetPath: AppAssets.profileHelpHeadset3d,
                fallbackIcon: LucideIcons.headphones,
                title: 'Support',
                onTap: () => Get.toNamed(AppRoutes.support),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recent Transactions Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.payoutsDetail),
              child: const Text(
                'See all',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Activity Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.clock3, color: Color(0xFF64748B), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No recent wallet deductions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Weekly settlements are transferred directly to your bank account.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuickServiceTile({
    required String assetPath,
    required IconData fallbackIcon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Image.asset(
              assetPath,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                fallbackIcon,
                size: 24,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
