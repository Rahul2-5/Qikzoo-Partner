import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
import '../widgets/available_gigs_section.dart';

/// The partner's weekly booking calendar. The content is intentionally
/// schedule-first: it makes the current booking state and earning potential
/// immediately clear before a rider opens an individual day.
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
          maxWidth: 640,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.md,
            ),
            children: [
              _GigsHeader(availability: availability),
              const SizedBox(height: AppSpacing.md),
              const _WeekOverview(),
              const SizedBox(height: AppSpacing.md),
              const _IncentiveStrip(),
              const SizedBox(height: AppSpacing.lg),
              const AvailableGigsSection(
                title: 'Available to book',
                actionLabel: 'See all',
              ),
              const SizedBox(height: AppSpacing.lg),
              const _ScheduleSectionHeader(),
              const SizedBox(height: AppSpacing.sm + 2),
              const _ScheduleCard.booked(),
              const SizedBox(height: AppSpacing.sm),
              const _ScheduleCard.open(day: '26', weekday: 'Sun'),
              const SizedBox(height: AppSpacing.sm),
              const _ScheduleCard.open(day: '27', weekday: 'Mon'),
              const SizedBox(height: AppSpacing.sm),
              const _ScheduleCard.open(day: '28', weekday: 'Tue'),
              const SizedBox(height: AppSpacing.sm),
              const _ScheduleCard.open(day: '29', weekday: 'Wed'),
              const SizedBox(height: AppSpacing.sm),
              const _ScheduleCard.locked(),
              const SizedBox(height: AppSpacing.md),
              const _SuperGigsInfoCard(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A concise, high-contrast weekly summary gives the schedule context before
/// riders scan individual days or choose another booking.
class _WeekOverview extends StatelessWidget {
  const _WeekOverview();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'This week: 6 gigs booked, 11 hours planned, estimated payout '
            '₹922 to ₹1,252.',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF283B8F), Color(0xFF536DFE)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2B3348A7),
                offset: Offset(0, 10),
                blurRadius: 22,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -42,
                top: -72,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 28,
                bottom: -66,
                child: Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBFC8FF).withValues(alpha: .15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .18),
                          ),
                        ),
                        child: Text(
                          'THIS WEEK',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        LucideIcons.calendarDays,
                        color: Color(0xFFDCE2FF),
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '25–30 Jul',
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFFDCE2FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Text(
                    'Your week is taking shape',
                    style: AppTypography.h2.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Keep the momentum going—more gig slots are open now.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: const Color(0xFFDCE2FF),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: const [
                      Expanded(
                        child: _WeekMetric(
                          value: '6',
                          label: 'Gigs booked',
                          icon: LucideIcons.badgeCheck,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _WeekMetric(
                          value: '₹922+',
                          label: 'Est. payout',
                          icon: LucideIcons.wallet,
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
          ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: const Color(0xFFE7EAFF)),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: const Color(0xFFDCE2FF),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _GigsHeader extends StatelessWidget {
  final RiderAvailabilityStatus? availability;

  const _GigsHeader({this.availability});

  void _showStatus(BuildContext context) {
    if (availability == RiderAvailabilityStatus.offline) {
      AppSnackBar.info(context, 'You are offline. Go online to book gigs.');
      return;
    }
    AppSnackBar.info(
      context,
      availability?.isOnlineFacing == true
          ? 'You are online and ready to book gigs.'
          : 'Your availability is being updated.',
    );
  }

  void _showUpdates(BuildContext context) => AppSnackBar.success(
        context,
        'You have no new gig updates.',
      );

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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep the wordmark centred while bounding the status label. The
        // former intrinsic-width Row overflowed with longer status values.
        final isCompact = constraints.maxWidth < 340;
        final statusWidth = isCompact ? 108.0 : 128.0;
        final wordmarkWidth = isCompact ? 60.0 : 72.0;

        return SizedBox(
          height: 58,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: statusWidth,
                  child: _AvailabilityControl(
                    label: statusLabel,
                    color: statusColor,
                    onTap: () => _showStatus(context),
                  ),
                ),
              ),
              SizedBox(
                width: wordmarkWidth,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _PartnerWordmark(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeaderIcon(
                      icon: LucideIcons.bell,
                      label: 'Gig notifications',
                      showDot: true,
                      onTap: () => _showUpdates(context),
                    ),
                    const SizedBox(width: 4),
                    _HeaderIcon(
                      icon: LucideIcons.helpCircle,
                      label: 'Gig help',
                      onTap: () => AppSnackBar.success(
                        context,
                        'Booking support is available in Help & Support.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AvailabilityControl extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AvailabilityControl({
    required this.label,
    required this.color,
    required this.onTap,
  });

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
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.control,
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: AppColors.textSecondary,
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
          Text('Qikzoo',
              style: AppTypography.h1.copyWith(
                  color: const Color(0xFF173B8D),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7)),
          Text('PARTNER',
              style: AppTypography.caption.copyWith(
                  color: const Color(0xFF11964B),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.7)),
        ],
      );
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showDot;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            onPressed: onTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: AppColors.textPrimary),
                if (showDot)
                  const Positioned(
                    top: -1,
                    right: -1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 7, height: 7),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _IncentiveStrip extends StatelessWidget {
  const _IncentiveStrip();

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          Expanded(
            child: _IncentiveCard(
              icon: LucideIcons.gift,
              iconColor: Color(0xFF10A64A),
              background: Color(0xFFF0F9F2),
              amount: '₹1,000',
              title: 'Earn extra',
              detail: 'Complete more gigs this weekend',
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _IncentiveCard(
              icon: LucideIcons.badgeCheck,
              iconColor: Color(0xFFF47A22),
              background: Color(0xFFFFF5EE),
              amount: '₹720',
              title: 'Earn extra',
              detail: 'For 8+ gigs · valid till Sat, 25 Jul',
            ),
          ),
        ],
      );
}

class _IncentiveCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color background;
  final String amount;
  final String title;
  final String detail;

  const _IncentiveCard({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.amount,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$title $amount. $detail',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => AppSnackBar.success(
                context, 'Your incentive details are ready to view.'),
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Ink(
              height: 136,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: Colors.white.withValues(alpha: .8)),
                boxShadow: AppShadows.control,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(icon, size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTypography.bodyMedium.copyWith(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.numericMd.copyWith(
                      fontSize: 22,
                      color: iconColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ScheduleSectionHeader extends StatelessWidget {
  const _ScheduleSectionHeader();

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your schedule', style: AppTypography.h2),
                  const SizedBox(height: 2),
                  Text(
                    '25–30 July · 6 days ahead',
                    style: AppTypography.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                'JULY',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            ),
          ],
        ),
      );
}

enum _GigDayState { booked, open, locked }

class _ScheduleCard extends StatelessWidget {
  final String day;
  final String weekday;
  final _GigDayState state;

  const _ScheduleCard._({
    required this.day,
    required this.weekday,
    required this.state,
  });

  const _ScheduleCard.booked()
      : this._(day: '25', weekday: 'Sat', state: _GigDayState.booked);

  const _ScheduleCard.open({required String day, required String weekday})
      : this._(day: day, weekday: weekday, state: _GigDayState.open);

  const _ScheduleCard.locked()
      : this._(day: '30', weekday: 'Thu', state: _GigDayState.locked);

  bool get _isBooked => state == _GigDayState.booked;
  bool get _isOpen => state == _GigDayState.open;

  @override
  Widget build(BuildContext context) {
    final dateColor = _isBooked
        ? AppColors.secondary
        : _isOpen
            ? const Color(0xFF0E9C48)
            : const Color(0xFF98A2B3);
    final title = _isBooked
        ? '6 gigs booked · 11 hours'
        : _isOpen
            ? 'Booking open'
            : 'Booking locked';
    final subtitle = _isBooked
        ? 'Estimated payout'
        : _isOpen
            ? 'Book now to earn more'
            : 'Booking will open at 9:50 AM, 26 Jul';

    return Semantics(
      button: true,
      label: '$weekday $day. $title. $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTap(context),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dateWidth = constraints.maxWidth < 320
                  ? 76.0
                  : constraints.maxWidth < 400
                      ? 88.0
                      : 100.0;

              return Ink(
                height: 112,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border:
                      Border.all(color: AppColors.border.withValues(alpha: .8)),
                  boxShadow: AppShadows.control,
                ),
                child: Row(
                  children: [
                    Container(
                      width: dateWidth,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: dateColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.card),
                          bottomLeft: Radius.circular(AppRadius.card),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day,
                            style: AppTypography.numericLg.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 30,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            weekday,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                        child: _DayContent(
                          state: state,
                          title: title,
                          subtitle: subtitle,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    final message = _isBooked
        ? 'Your booked gigs are ready to review.'
        : _isOpen
            ? 'Booking is open for $weekday, $day July.'
            : 'Booking for $weekday, $day July is not open yet.';
    AppSnackBar.success(context, message);
  }
}

class _DayContent extends StatelessWidget {
  final _GigDayState state;
  final String title;
  final String subtitle;

  const _DayContent({
    required this.state,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final booked = state == _GigDayState.booked;
    final open = state == _GigDayState.open;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (open) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0E9C48),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text('SUPER GIGS',
                style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .35)),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium
                    .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            if (!booked && state != _GigDayState.locked)
              const Icon(LucideIcons.chevronRight,
                  size: 21, color: AppColors.textSecondary),
            if (state == _GigDayState.locked)
              const Icon(LucideIcons.lock,
                  size: 20, color: AppColors.textPrimary),
          ],
        ),
        const SizedBox(height: 5),
        if (booked)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(subtitle,
                  style: AppTypography.caption.copyWith(fontSize: 12)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EC),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text('₹922 – ₹1,252',
                    style: AppTypography.caption.copyWith(
                        color: const Color(0xFF14863F),
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!open) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(LucideIcons.hourglass,
                      size: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(fontSize: 13)),
              ),
            ],
          ),
      ],
    );
  }
}

class _SuperGigsInfoCard extends StatelessWidget {
  const _SuperGigsInfoCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFD9E4FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.badgeInfo,
                  color: AppColors.primary, size: 27),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What are Super Gigs?',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 14)),
                  const SizedBox(height: 3),
                  Text('Higher earnings and priority support for Super Gigs.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => AppSnackBar.success(
                  context, 'Super Gigs help is available in Help & Support.'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: Color(0xFFB8C4E6)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Know more',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.primary, fontSize: 11)),
            ),
          ],
        ),
      );
}

@Preview(name: 'Gigs schedule', group: 'Gigs', size: Size(390, 844))
Widget gigsScreenPreview() => const ProviderScope(
      child: MaterialApp(home: GigsScreen()),
    );
