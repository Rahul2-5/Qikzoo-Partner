import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/wallet/wallet_model.dart';
import '../../../providers/wallet/wallet_provider.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
import '../../wallet/widgets/deposit_cash_sheet.dart';

class PayoutsDetailScreen extends ConsumerStatefulWidget {
  const PayoutsDetailScreen({super.key});

  @override
  ConsumerState<PayoutsDetailScreen> createState() => _PayoutsDetailScreenState();
}

class _PayoutsDetailScreenState extends ConsumerState<PayoutsDetailScreen> {
  DateTime _selectedWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  bool _isPlayingAudio = false;

  void _previousWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    if (_selectedWeekStart.isBefore(currentWeekStart)) {
      setState(() {
        _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);

    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
    final dateRangeStr =
        '${DateFormat('d MMM').format(_selectedWeekStart)}-${DateFormat('d MMM').format(weekEnd)}';

    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final canGoNext = _selectedWeekStart.isBefore(currentWeekStart);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Back Arrow and Title
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
                    'Payouts',
                    style: AppTypography.h1.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date Range Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _previousWeek,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D8538),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    dateRangeStr,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: canGoNext ? _nextWeek : null,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: canGoNext
                            ? const Color(0xFF0D8538)
                            : const Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.chevronRight,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Main Scrollable Area
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF0D8538),
                  onRefresh: () async {
                    ref.invalidate(walletProvider);
                    await ref.read(walletProvider.future);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: walletAsync.when(
                      loading: () => const WalletLoadingShimmer(),
                      error: (_, __) => _buildErrorState(),
                      data: (wallet) => _buildPayoutsContent(wallet, dateRangeStr),
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(LucideIcons.wallet, size: 40, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            const Text('Failed to load payout details'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(walletProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutsContent(WalletModel wallet, String dateRangeStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Available cash limit pill banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9C3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFEF08A)),
          ),
          child: Center(
            child: Text(
              'Available cash limit : ${CurrencyFormatter.rupeesPrecise(wallet.cashLimit)}',
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Hero Cash Left Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Icon
              Image.asset(
                AppAssets.profileEarningsWallet3d,
                width: 38,
                height: 38,
                errorBuilder: (_, __, ___) => const Icon(
                  LucideIcons.wallet,
                  size: 32,
                  color: Color(0xFF0D8538),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'CASH LEFT WITH YOU',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.rupeesPrecise(wallet.floatingCash),
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'PlusJakartaSans',
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),

              // Audio Scrubber Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isPlayingAudio = !_isPlayingAudio),
                      child: Icon(
                        _isPlayingAudio
                            ? LucideIcons.pauseCircle
                            : LucideIcons.play,
                        color: const Color(0xFF111827),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 2,
                            color: const Color(0xFFD1D5DB),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF111827),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'A/अ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Deposit now Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    DepositCashSheet.show(
                      context,
                      currentCashInHand: wallet.floatingCash,
                      onDepositSuccess: () {
                        ref.invalidate(walletProvider);
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D8538),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Deposit now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Bank transfers card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF6B7280),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateRangeStr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'No bank transfers this week',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Image.asset(
                AppAssets.profileEarningsWallet3d,
                width: 38,
                height: 38,
                errorBuilder: (_, __, ___) => const Icon(
                  LucideIcons.banknote,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Empty deliveries state section
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Column(
            children: [
              Image.asset(
                AppAssets.dashboardGigsCompleted3d,
                width: 58,
                height: 58,
                errorBuilder: (_, __, ___) => const Icon(
                  LucideIcons.package,
                  size: 48,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'No deliveries yet',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Start your first order this week',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
