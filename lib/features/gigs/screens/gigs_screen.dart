import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/app_bottom_nav.dart';

/// The partner's weekly booking calendar. The content is intentionally
/// schedule-first: it makes the current booking state and earning potential
/// immediately clear before a rider opens an individual day.
class GigsScreen extends StatelessWidget {
  const GigsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ResponsiveFrame(
                  maxWidth: 640,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.md,
                    ),
                    children: const [
                      _GigsHeader(),
                      SizedBox(height: AppSpacing.md),
                      _IncentiveStrip(),
                      SizedBox(height: AppSpacing.lg),
                      _MonthDivider(month: 'JULY'),
                      SizedBox(height: AppSpacing.md),
                      _ScheduleCard.booked(),
                      SizedBox(height: AppSpacing.sm),
                      _ScheduleCard.open(day: '26', weekday: 'Sun'),
                      SizedBox(height: AppSpacing.sm),
                      _ScheduleCard.open(day: '27', weekday: 'Mon'),
                      SizedBox(height: AppSpacing.sm),
                      _ScheduleCard.open(day: '28', weekday: 'Tue'),
                      SizedBox(height: AppSpacing.sm),
                      _ScheduleCard.open(day: '29', weekday: 'Wed'),
                      SizedBox(height: AppSpacing.sm),
                      _ScheduleCard.locked(),
                      SizedBox(height: AppSpacing.md),
                      _SuperGigsInfoCard(),
                    ],
                  ),
                ),
              ),
              const AppBottomNav(currentIndex: 1),
            ],
          ),
        ),
      );
}

class _GigsHeader extends StatelessWidget {
  const _GigsHeader();

  void _showStatus(BuildContext context) => AppSnackBar.success(
        context,
        'You are online and ready to book gigs.',
      );

  void _showUpdates(BuildContext context) => AppSnackBar.success(
        context,
        'You have no new gig updates.',
      );

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 58,
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'You are online',
              child: InkWell(
                onTap: () => _showStatus(context),
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.control,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF17A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text('Online',
                          style:
                              AppTypography.bodyMedium.copyWith(fontSize: 13)),
                      const SizedBox(width: 5),
                      const Icon(LucideIcons.chevronDown,
                          size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            const _PartnerWordmark(),
            const Spacer(),
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
                  context, 'Booking support is available in Help & Support.'),
            ),
          ],
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
        child: IconButton(
          onPressed: onTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 23, color: AppColors.textPrimary),
              if (showDot)
                const Positioned(
                  top: -1,
                  right: -1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: AppColors.error, shape: BoxShape.circle),
                    child: SizedBox(width: 7, height: 7),
                  ),
                ),
            ],
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
              height: 126,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: Colors.white.withValues(alpha: .8)),
                boxShadow: AppShadows.control,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 23, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppTypography.bodyMedium
                                .copyWith(fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(amount,
                            style: AppTypography.numericMd
                                .copyWith(fontSize: 22, color: iconColor)),
                        const Spacer(),
                        Text(detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                                fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 38),
                    child: Icon(LucideIcons.chevronRight,
                        size: 17, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _MonthDivider extends StatelessWidget {
  final String month;
  const _MonthDivider({required this.month});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(month,
                style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                    fontSize: 14)),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
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
          child: Ink(
            height: 112,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border.withValues(alpha: .8)),
              boxShadow: AppShadows.control,
            ),
            child: Row(
              children: [
                Container(
                  width: 86,
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
                      Text(day,
                          style: AppTypography.numericLg.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 30)),
                      const SizedBox(height: 1),
                      Text(weekday,
                          style: AppTypography.bodyMedium
                              .copyWith(color: Colors.white, fontSize: 15)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
                    child: _DayContent(
                      state: state,
                      title: title,
                      subtitle: subtitle,
                    ),
                  ),
                ),
              ],
            ),
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
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium
                      .copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
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
          Row(
            children: [
              Text(subtitle,
                  style: AppTypography.caption.copyWith(fontSize: 12)),
              const Spacer(),
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
Widget gigsScreenPreview() => const MaterialApp(home: GigsScreen());
