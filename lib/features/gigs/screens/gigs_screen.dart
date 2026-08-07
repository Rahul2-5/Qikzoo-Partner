import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/dashboard/dashboard_stats_model.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';

/// The partner's weekly gig schedule and earning opportunities.
class GigsScreen extends ConsumerWidget {
  const GigsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability =
        ref.watch(dashboardStatsProvider).valueOrNull?.availabilityStatus;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTabScaffold(
        currentIndex: 1,
        child: ResponsiveFrame(
          maxWidth: 680,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.xl,
            ),
            children: [
              _GigsHeader(availability: availability),
              const SizedBox(height: AppSpacing.md),
              const _WeekOverview(),
              const SizedBox(height: AppSpacing.lg),
              const _EarningOpportunities(),
              const SizedBox(height: AppSpacing.lg),
              const _ScheduleModePicker(),
              const SizedBox(height: AppSpacing.md),
              const _GigDayCard.booked(),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              const _GigDayCard.open(day: '26', weekday: 'Sun'),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              const _GigDayCard.open(day: '27', weekday: 'Mon'),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              const _GigDayCard.open(day: '28', weekday: 'Tue'),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              const _GigDayCard.open(day: '29', weekday: 'Wed'),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              const _GigDayCard.locked(),
              const SizedBox(height: AppSpacing.lg),
              const _SuperGigsInfoCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GigsHeader extends StatelessWidget {
  const _GigsHeader({this.availability});

  final RiderAvailabilityStatus? availability;

  @override
  Widget build(BuildContext context) {
    final isOnline = availability?.isOnlineFacing ?? false;
    final isOffline = availability == RiderAvailabilityStatus.offline;
    final statusLabel = availability?.label ?? 'Checking status';
    final statusColor = isOnline
        ? AppColors.success
        : isOffline
            ? AppColors.textSecondary
            : AppColors.warning;

    return SizedBox(
      height: 58,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The previous stacked header let its left and right controls cover
          // the wordmark on narrow phones. A regular row gives every control a
          // real width, while retaining the brand on standard phone widths.
          final showWordmark = constraints.maxWidth >= 280;

          return Row(
            children: [
              _AvailabilityControl(
                label: statusLabel,
                color: statusColor,
                compact: !showWordmark,
                onTap: () => AppSnackBar.info(
                  context,
                  isOnline
                      ? 'You are online and ready to book gigs.'
                      : 'Go online to make yourself available for gigs.',
                ),
              ),
              if (showWordmark) ...[
                const Spacer(),
                const _PartnerWordmark(),
                const Spacer(),
              ] else
                const Spacer(),
              _HeaderAction(
                icon: LucideIcons.bell,
                label: 'Gig notifications',
                showDot: true,
                onTap: () => AppSnackBar.success(
                    context, 'You have no new gig updates.'),
              ),
              _HeaderAction(
                icon: LucideIcons.helpCircle,
                label: 'Gig help',
                onTap: () => AppSnackBar.info(
                  context,
                  'Booking support is available in Help & Support.',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AvailabilityControl extends StatelessWidget {
  const _AvailabilityControl({
    required this.label,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'You are $label',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: Ink(
              height: 44,
              width: compact ? 118 : 128,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border:
                    Border.all(color: AppColors.border.withValues(alpha: .75)),
                boxShadow: AppShadows.control,
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronDown,
                    color: AppColors.textPrimary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _PartnerWordmark extends StatelessWidget {
  const _PartnerWordmark();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Qikzoo',
            style: AppTypography.h1.copyWith(
              color: AppColors.primaryDark,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
          ),
          Text(
            'PARTNER',
            style: AppTypography.caption.copyWith(
              color: AppColors.success,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.65,
            ),
          ),
        ],
      );
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: IconButton(
          onPressed: onTap,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 36, height: 44),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 22, color: AppColors.textPrimary),
              if (showDot)
                const Positioned(
                  right: -2,
                  top: -2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(width: 8, height: 8),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _WeekOverview extends StatelessWidget {
  const _WeekOverview();

  @override
  Widget build(BuildContext context) => Semantics(
        label:
            'This week: 6 gigs booked, 11 hours planned, estimated payout ₹922 or more.',
        child: Container(
          height: 284,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(AppRadius.sheet + 4),
            boxShadow: AppShadows.cta,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                      right: 8, top: 52, child: _Sparkle(size: 16)),
                  const Positioned(
                      right: 154, top: 22, child: _Sparkle(size: 10)),
                  Positioned(
                    right: compact ? -12 : -28,
                    bottom: compact ? -4 : -24,
                    child: Opacity(
                      opacity: .96,
                      child: Image.asset(
                        AppAssets.gigCalendar3d,
                    width: compact ? 154 : 190,
                    cacheWidth: compact ? 308 : 424,
                        fit: BoxFit.contain,
                        semanticLabel: 'Booked schedule calendar',
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          _FrostedLabel(label: 'THIS WEEK'),
                          Spacer(),
                          _FrostedLabel(
                            label: '25 – 30 Jul',
                            icon: LucideIcons.calendarDays,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your week is taking shape 🚀',
                        style: AppTypography.h2.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SizedBox(
                        width: compact ? 166 : 218,
                        child: Text(
                          'Keep the momentum going—more gig slots are open now.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.primarySoft,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Row(
                        children: [
                          Expanded(
                            child: _WeekMetric(
                              value: '6',
                              label: 'Gigs booked',
                              icon: LucideIcons.briefcase,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _WeekMetric(
                              value: '₹922+',
                              label: 'Est. payout',
                              icon: LucideIcons.walletCards,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _WeekMetric(
                              value: '11h',
                              label: 'On the road',
                              icon: LucideIcons.clock3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Icon(
        LucideIcons.sparkles,
        size: size,
        color: AppColors.onPrimary.withValues(alpha: .72),
      );
}

class _FrostedLabel extends StatelessWidget {
  const _FrostedLabel({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.onPrimary.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.onPrimary.withValues(alpha: .14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.onPrimary, size: 15),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: icon == null ? .65 : 0,
              ),
            ),
          ],
        ),
      );
}

class _WeekMetric extends StatelessWidget {
  const _WeekMetric({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        height: 92,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.onPrimary.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.onPrimary.withValues(alpha: .16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primarySoft, size: 18),
            const Spacer(),
            FittedBox(
              child: Text(
                value,
                style: AppTypography.numericMd.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.primarySoft,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _EarningOpportunities extends StatelessWidget {
  const _EarningOpportunities();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 340
            ? const _CompactEarningOpportunities()
            : const Row(
                children: [
                  Expanded(
                    child: _OpportunityCard(
                      title: 'Weekend Boost',
                      value: '₹1,000',
                      subtitle: 'Complete more gigs\nthis weekend',
                      valueColor: AppColors.success,
                      background: Color(0xFFEAF8F0),
                      asset: AppAssets.weekendBoost3d,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _OpportunityCard(
                      title: 'Extra Earnings',
                      value: '₹720',
                      subtitle: 'For 8+ gigs • valid till\nSat, 25 Jul',
                      valueColor: AppColors.warning,
                      background: Color(0xFFFFF4ED),
                      asset: AppAssets.extraEarnings3d,
                    ),
                  ),
                ],
              ),
      );
}

class _CompactEarningOpportunities extends StatelessWidget {
  const _CompactEarningOpportunities();

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          _OpportunityCard(
            title: 'Weekend Boost',
            value: '₹1,000',
            subtitle: 'Complete more gigs\nthis weekend',
            valueColor: AppColors.success,
            background: Color(0xFFEAF8F0),
            asset: AppAssets.weekendBoost3d,
          ),
          SizedBox(height: AppSpacing.sm),
          _OpportunityCard(
            title: 'Extra Earnings',
            value: '₹720',
            subtitle: 'For 8+ gigs • valid till\nSat, 25 Jul',
            valueColor: AppColors.warning,
            background: Color(0xFFFFF4ED),
            asset: AppAssets.extraEarnings3d,
          ),
        ],
      );
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.valueColor,
    required this.background,
    required this.asset,
  });
  final String title;
  final String value;
  final String subtitle;
  final Color valueColor;
  final Color background;
  final String asset;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$title, $value. $subtitle',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () =>
                AppSnackBar.info(context, '$title details are coming soon.'),
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            child: Ink(
              height: 150,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadius.sheet),
                border: Border.all(color: valueColor.withValues(alpha: .16)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -12,
                    bottom: 6,
                    child: Image.asset(
                      asset,
                      width: 112,
                      height: 112,
                      cacheWidth: 224,
                    ),
                  ),
                  Positioned(
                    left: 82,
                    right: 10,
                    top: 18,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                    ),
                  ),
                  Positioned(
                    left: 82,
                    right: 8,
                    top: 45,
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: AppTypography.numericMd.copyWith(
                          color: valueColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 82,
                    right: 8,
                    bottom: 16,
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption
                          .copyWith(fontSize: 9.5, height: 1.45),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: _RoundArrow(color: valueColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ScheduleModePicker extends StatelessWidget {
  const _ScheduleModePicker();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.calendarClock,
                color: AppColors.secondary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Text(
                  'Your Gigs This Week',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h2.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => AppSnackBar.info(
                  context,
                  'Calendar view is coming soon.',
                ),
                icon: const Icon(LucideIcons.calendarDays, size: 18),
                label: Text(compact ? 'Calendar' : 'Calendar View'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: BorderSide(
                    color: AppColors.secondary.withValues(alpha: .2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  textStyle: AppTypography.bodyMedium.copyWith(fontSize: 12),
                ),
              ),
            ],
          );
        },
      );
}

enum _GigDayState { booked, open, locked }

class _GigDayCard extends StatelessWidget {
  const _GigDayCard._({
    required this.day,
    required this.weekday,
    required this.state,
  });
  const _GigDayCard.booked()
      : this._(day: '25', weekday: 'Sat', state: _GigDayState.booked);
  const _GigDayCard.open({required String day, required String weekday})
      : this._(day: day, weekday: weekday, state: _GigDayState.open);
  const _GigDayCard.locked()
      : this._(day: '30', weekday: 'Thu', state: _GigDayState.locked);

  final String day;
  final String weekday;
  final _GigDayState state;

  @override
  Widget build(BuildContext context) {
    final isBooked = state == _GigDayState.booked;
    final isOpen = state == _GigDayState.open;
    final panelColor = isBooked
        ? AppColors.secondary
        : isOpen
            ? AppColors.success
            : AppColors.textDisabled;

    return Semantics(
      button: state != _GigDayState.locked,
      label: isBooked
          ? '$weekday $day. 6 gigs booked, 11 hours, estimated payout ₹922 to ₹1,252.'
          : isOpen
              ? '$weekday $day. Super Gigs booking open.'
              : '$weekday $day. Booking locked.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: state == _GigDayState.locked
              ? null
              : () => AppSnackBar.info(
                    context,
                    isBooked
                        ? 'Your booked gigs for Saturday are ready to view.'
                        : 'Gig booking for $weekday is now open.',
                  ),
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          child: Ink(
            height: 114,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              border: Border.all(color: AppColors.border.withValues(alpha: .7)),
              boxShadow: AppShadows.control,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 340;

                return Row(
                  children: [
                    Container(
                      width: compact ? 68 : 82,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(AppRadius.sheet),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day,
                            style: AppTypography.numericLg.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 31,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            weekday,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 13,
                            ),
                          ),
                          if (isBooked) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.onPrimary.withValues(alpha: .18),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.chip),
                              ),
                              child: Text(
                                'TODAY',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.onPrimary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _DayContent(state: state),
                    ),
                    if (!compact) ...[
                      _DayVisual(state: state),
                      const SizedBox(width: 6),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: isBooked || isOpen
                          ? const _RoundArrow(color: AppColors.textSecondary)
                          : const Icon(LucideIcons.lock,
                              color: AppColors.textSecondary, size: 32),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DayContent extends StatelessWidget {
  const _DayContent({required this.state});
  final _GigDayState state;

  @override
  Widget build(BuildContext context) {
    if (state == _GigDayState.booked) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('6 gigs booked · 11 hours',
              style: AppTypography.bodyMedium.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Estimated payout',
                  style: AppTypography.caption.copyWith(fontSize: 10.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  '₹922 – ₹1,252',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    if (state == _GigDayState.open) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              '⚡ SUPER GIGS',
              style: AppTypography.caption.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Booking open',
              style: AppTypography.bodyMedium.copyWith(fontSize: 16)),
          const SizedBox(height: 2),
          Text('Book now to earn more',
              style: AppTypography.caption.copyWith(fontSize: 11)),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Booking locked',
            style: AppTypography.bodyMedium.copyWith(fontSize: 16)),
        const SizedBox(height: 5),
        Text('⌛ Booking will open at 9:50 AM, 26 Jul',
            style: AppTypography.caption.copyWith(fontSize: 10.5)),
      ],
    );
  }
}

class _DayVisual extends StatelessWidget {
  const _DayVisual({required this.state});
  final _GigDayState state;

  @override
  Widget build(BuildContext context) {
    if (state == _GigDayState.locked) return const SizedBox(width: 0);
    return Image.asset(
      state == _GigDayState.booked
          ? AppAssets.bookedPayout3d
          : AppAssets.gigCalendar3d,
      width: state == _GigDayState.booked ? 72 : 56,
      height: state == _GigDayState.booked ? 82 : 72,
      cacheWidth: state == _GigDayState.booked ? 144 : 112,
      fit: BoxFit.contain,
    );
  }
}

class _RoundArrow extends StatelessWidget {
  const _RoundArrow({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: AppShadows.control,
        ),
        child: Icon(LucideIcons.chevronRight, color: color, size: 20),
      );
}

class _SuperGigsInfoCard extends StatelessWidget {
  const _SuperGigsInfoCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                boxShadow: AppShadows.cta,
              ),
              child: const Icon(LucideIcons.star,
                  color: AppColors.onPrimary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What are Super Gigs?',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(
                    'Higher earnings and priority support for Super Gigs.',
                    style: AppTypography.caption.copyWith(fontSize: 10.5),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => AppSnackBar.info(
                  context, 'Super Gigs help is available in Help & Support.'),
              iconAlignment: IconAlignment.end,
              icon: const Icon(LucideIcons.chevronRight, size: 16),
              label: const Text('Know more'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.bodyMedium.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      );
}

@Preview(name: 'Gigs schedule', group: 'Gigs', size: Size(390, 844))
Widget gigsScreenPreview() => const ProviderScope(
      child: MaterialApp(home: GigsScreen()),
    );
