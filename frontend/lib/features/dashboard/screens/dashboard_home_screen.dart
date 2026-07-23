import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/dashboard/dashboard_stats_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/todays_earnings_card.dart';

/// Rider dashboard home — reached once onboarding is APPROVED and the
/// account is ACTIVE (see NextOnboardingStepResolver's `isActive` branch).
/// Read-only summary of today's shift plus the Go Online/Offline toggle;
/// Orders/Wallet/Earnings history/Notifications/Live tracking are later
/// phases and deliberately not linked from here yet.
class DashboardHomeScreen extends ConsumerStatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  ConsumerState<DashboardHomeScreen> createState() =>
      _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends ConsumerState<DashboardHomeScreen> {
  bool _isTogglingAvailability = false;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _onToggleAvailability(RiderAvailabilityStatus current) async {
    if (_isTogglingAvailability) return;
    setState(() => _isTogglingAvailability = true);
    try {
      if (current.isOnlineFacing) {
        await ref.read(dashboardStatsProvider.notifier).goOffline();
      } else {
        await ref.read(dashboardStatsProvider.notifier).goOnline();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await ref.read(authSessionProvider.notifier).logout();
        if (!mounted) return;
        Get.offAllNamed(AppRoutes.welcome);
        return;
      }
      AppSnackBar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isTogglingAvailability = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 640,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorView(
              message: error is ApiException
                  ? error.message
                  : 'Could not load your dashboard.',
              onRetry: () => ref.read(dashboardStatsProvider.notifier).refresh(),
            ),
            data: (stats) => RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: () =>
                  ref.read(dashboardStatsProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  _GreetingRow(
                    greeting: _greeting,
                    riderName: stats.riderName,
                    status: stats.availabilityStatus,
                    isToggling: _isTogglingAvailability,
                    onToggle: () => _onToggleAvailability(stats.availabilityStatus),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TodaysEarningsCard(amount: stats.todaysEarningsPaise / 100.0),
                  const SizedBox(height: AppSpacing.lg),
                  _StatGrid(stats: stats),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  final String greeting;
  final String riderName;
  final RiderAvailabilityStatus status;
  final bool isToggling;
  final VoidCallback onToggle;

  const _GreetingRow({
    required this.greeting,
    required this.riderName,
    required this.status,
    required this.isToggling,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final online = status.isOnlineFacing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style:
                    AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                riderName.isEmpty ? 'Rider' : riderName,
                style: AppTypography.h1.copyWith(fontSize: 22),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                status.label,
                style: AppTypography.caption.copyWith(
                  color: online ? AppColors.success : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          button: true,
          label: online
              ? 'Currently ${status.label}. Tap to go offline'
              : 'Currently ${status.label}. Tap to go online',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('availability-toggle'),
              onTap: isToggling ? null : onToggle,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 104),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: online ? AppColors.successBg : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                    color: online
                        ? AppColors.success.withValues(alpha: 0.24)
                        : AppColors.border,
                  ),
                  boxShadow: AppShadows.control,
                ),
                child: Center(
                  child: isToggling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: online
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              online ? 'Online' : 'Offline',
                              style: AppTypography.bodyMedium.copyWith(
                                color: online
                                    ? AppColors.success
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  final DashboardStatsModel stats;

  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        icon: LucideIcons.packageCheck,
        label: "Today's deliveries",
        value: '${stats.todaysDeliveries}',
        color: AppColors.secondary,
      ),
      _StatTile(
        icon: LucideIcons.wallet,
        label: 'Wallet balance',
        value: '₹${(stats.walletBalancePaise / 100.0).toStringAsFixed(0)}',
        color: AppColors.primary,
      ),
      _StatTile(
        icon: LucideIcons.thumbsUp,
        label: 'Acceptance rate',
        value: stats.acceptanceRatePercent != null
            ? '${stats.acceptanceRatePercent!.toStringAsFixed(0)}%'
            : '—',
        color: AppColors.accent,
      ),
      _StatTile(
        icon: LucideIcons.checkCircle2,
        label: 'Completion rate',
        value: stats.completionRatePercent != null
            ? '${stats.completionRatePercent!.toStringAsFixed(0)}%'
            : '—',
        color: AppColors.success,
      ),
      _StatTile(
        icon: LucideIcons.star,
        label: 'Rating',
        value: stats.rating.toStringAsFixed(1),
        color: AppColors.warning,
      ),
      _StatTile(
        icon: LucideIcons.mapPin,
        label: 'Working zone',
        value: stats.workingZone ?? '—',
        color: AppColors.secondary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 480 ? 3 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.05,
          children: tiles,
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          boxShadow: AppShadows.control,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: AppTypography.numericMd,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Could not load your dashboard', style: AppTypography.body),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style:
                  AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
