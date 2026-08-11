import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/navigation/partner_app_header.dart';

const _positive = Color(0xFF20B957);
const _positiveSoft = Color(0xFFEAF9EF);

class TodayPerformanceHeader extends StatelessWidget {
  const TodayPerformanceHeader({
    super.key,
    this.unreadNotificationCount = 0,
    this.onNotifications,
    this.isOnline = false,
  });

  final int unreadNotificationCount;
  final VoidCallback? onNotifications;
  final bool isOnline;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final useStackedTitle = constraints.maxWidth < 360 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          final dateLabel = DateFormat('d MMMM, EEEE').format(DateTime.now());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PartnerAppHeader(
                subtitle: 'Earnings overview',
                unreadNotificationCount: unreadNotificationCount,
                onNotifications: onNotifications ?? () {},
              ),
              const SizedBox(height: AppSpacing.lg),
              if (useStackedTitle) ...[
                Text("Today's Earnings", style: AppTypography.h1),
                const SizedBox(height: 3),
                Text(dateLabel, style: AppTypography.body),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _OnlineBadge(isOnline: isOnline),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's Earnings", style: AppTypography.h1),
                          const SizedBox(height: 3),
                          Text(dateLabel, style: AppTypography.body),
                        ],
                      ),
                    ),
                    _OnlineBadge(isOnline: isOnline),
                  ],
                ),
            ],
          );
        },
      );
}

/// Shows the real total for whichever period the rider selected
/// (today/this-week/lifetime) — earnings + tips, both from
/// `GET /rider/earnings/summary`. No category split (order pay vs
/// incentives vs distance pay) or day-over-day delta exists on the
/// backend, so neither is shown here.
class TodayEarningsCard extends StatelessWidget {
  final double total;
  final double earnings;
  final double tips;
  final int deliveries;

  const TodayEarningsCard({
    super.key,
    required this.total,
    required this.earnings,
    required this.tips,
    required this.deliveries,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        label:
            "Total earnings ${CurrencyFormatter.rupeesPrecise(total)}",
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
                AppColors.secondary
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332457BF),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -36,
                top: -62,
                child: _GlowCircle(
                    size: 176, color: Colors.white.withValues(alpha: 0.08)),
              ),
              Positioned(
                right: 2,
                top: 8,
                child: IgnorePointer(
                  child: Image.asset(
                    AppAssets.earningsWallet3d,
                    width: 118,
                    height: 118,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 72),
                    child: Text(
                      'Total Earnings',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormatter.rupeesPrecise(total),
                      style: AppTypography.display.copyWith(
                        color: Colors.white,
                        fontSize: 40,
                        letterSpacing: -1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      '$deliveries ${deliveries == 1 ? 'delivery' : 'deliveries'}',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .14)),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _EarningValue(
                            icon: LucideIcons.shoppingBag,
                            iconColor: AppColors.secondary,
                            label: 'Delivery Earnings',
                            amount: earnings,
                          ),
                        ),
                        _Divider(color: Colors.white.withValues(alpha: .18)),
                        Expanded(
                          child: _EarningValue(
                            icon: LucideIcons.circleDollarSign,
                            iconColor: const Color(0xFF8C67F6),
                            label: 'Tips',
                            amount: tips,
                            amountColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

/// Real delivery count for the same period as [TodayEarningsCard]. There is
/// no backend field for online/shift duration, so that stat is not shown
/// rather than fabricated.
class TodayStatGrid extends StatelessWidget {
  const TodayStatGrid({super.key, required this.deliveries});

  final int deliveries;

  @override
  Widget build(BuildContext context) => _PerformanceStatCard(
        icon: LucideIcons.shoppingBag,
        tint: const Color(0xFFFFF3E7),
        iconColor: const Color(0xFFE6892E),
        title: 'Completed Deliveries',
        value: '$deliveries',
      );
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card + 2),
          border: Border.all(color: AppColors.border.withValues(alpha: .55)),
          boxShadow: AppShadows.control,
        ),
        child: child,
      );
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isOnline ? _positiveSoft : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusDot(isOnline: isOnline),
            const SizedBox(width: 7),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: AppTypography.bodyMedium.copyWith(
                color: isOnline ? _positive : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 11,
        height: 11,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isOnline ? _positive : AppColors.textDisabled,
            shape: BoxShape.circle,
          ),
        ),
      );
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _EarningValue extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final double amount;
  final Color? amountColor;
  const _EarningValue(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.amount,
      this.amountColor});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .88),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: .74),
                        fontSize: 10)),
                const SizedBox(height: 3),
                Text(CurrencyFormatter.rupeesPrecise(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: amountColor ?? Colors.white,
                      fontSize: 14,
                    )),
              ],
            ),
          ),
        ],
      );
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 42, color: color);
}

class _PerformanceStatCard extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String title;
  final String value;
  const _PerformanceStatCard({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => _SurfaceCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(icon, size: 21, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(value,
                      style: AppTypography.numericMd.copyWith(fontSize: 19)),
                ],
              ),
            ),
          ],
        ),
      );
}
