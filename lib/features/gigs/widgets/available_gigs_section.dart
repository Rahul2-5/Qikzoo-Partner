import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/navigation/section_header.dart';

class GigOffer {
  final String title;
  final String zone;
  final String startsAt;
  final String orders;
  final String ridersNeeded;
  final String guaranteedPay;
  final String peakBonus;
  final String peakThreshold;
  final String extraBonus;
  final Color color;
  final IconData icon;
  final bool popular;

  const GigOffer({
    required this.title,
    required this.zone,
    required this.startsAt,
    required this.orders,
    required this.ridersNeeded,
    required this.guaranteedPay,
    required this.peakBonus,
    required this.peakThreshold,
    required this.extraBonus,
    required this.color,
    required this.icon,
    this.popular = false,
  });
}

const availableGigs = <GigOffer>[
  GigOffer(
      title: '2 Hour Delivery Gig',
      zone: 'Andheri East Zone',
      startsAt: 'Starts in 15 mins',
      orders: '8 – 12',
      ridersNeeded: '5 riders needed',
      guaranteedPay: '₹300',
      peakBonus: '+ ₹25',
      peakThreshold: 'After 8 orders',
      extraBonus: '₹100',
      color: Color(0xFF1EAD4D),
      icon: LucideIcons.timer,
      popular: true),
  GigOffer(
      title: 'Lunch Rush Gig',
      zone: 'Powai Zone',
      startsAt: 'Starts at 12:00 PM',
      orders: '10+',
      ridersNeeded: '6 riders needed',
      guaranteedPay: '₹350',
      peakBonus: '+ ₹30',
      peakThreshold: 'After 10 orders',
      extraBonus: '₹120',
      color: Color(0xFFF47B20),
      icon: LucideIcons.utensils),
  GigOffer(
      title: 'Evening Express Gig',
      zone: 'Vikhroli & Kanjurmarg Zone',
      startsAt: 'Starts at 5:00 PM',
      orders: '9 – 14',
      ridersNeeded: '4 riders needed',
      guaranteedPay: '₹320',
      peakBonus: '+ ₹28',
      peakThreshold: 'After 9 orders',
      extraBonus: '₹100',
      color: Color(0xFF2A6ADF),
      icon: LucideIcons.bike),
];

/// Reusable gig list used on the dashboard and the dedicated Gigs tab.
class AvailableGigsSection extends StatelessWidget {
  /// Use [startIndex] when a higher-priority gig is already shown as a Home
  /// hero, so the same booking opportunity is not repeated immediately.
  final bool showAll;
  final int startIndex;
  final String title;
  final String? actionLabel;

  const AvailableGigsSection({
    super.key,
    this.showAll = false,
    this.startIndex = 0,
    this.title = 'Available Gigs',
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final source = showAll ? availableGigs : availableGigs.take(2);
    final boundedStartIndex = startIndex.clamp(0, source.length);
    final gigs = source.skip(boundedStartIndex).toList();
    final resolvedActionLabel = actionLabel ?? (showAll ? null : 'View all');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: title,
          actionLabel: resolvedActionLabel,
          onActionTap: resolvedActionLabel == null
              ? null
              : () => Get.toNamed(AppRoutes.gigs),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        for (var index = 0; index < gigs.length; index++) ...[
          GigOfferCard(gig: gigs[index]),
          if (index < gigs.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class GigOfferCard extends StatelessWidget {
  final GigOffer gig;
  const GigOfferCard({super.key, required this.gig});

  void _bookGig(BuildContext context) => AppSnackBar.success(
      context, '${gig.title} reserved. Check your schedule for details.');

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: '${gig.title}, ${gig.zone}, ${gig.startsAt}, '
            '${gig.ridersNeeded}, guaranteed ${gig.guaranteedPay}',
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md - 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            border: Border.all(color: AppColors.border.withValues(alpha: .76)),
            boxShadow: AppShadows.control,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GigDurationPanel(gig: gig),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            gig.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _PayBadge(gig: gig),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            gig.zone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _GigTimingPill(gig: gig),
                    const SizedBox(height: AppSpacing.sm),
                    _GigHighlights(gig: gig),
                    const SizedBox(height: AppSpacing.sm + 2),
                    Row(
                      children: [
                        Expanded(
                          child: _GigMeta(
                            icon: LucideIcons.users,
                            value: gig.ridersNeeded,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          height: 40,
                          child: FilledButton(
                            onPressed: () => _bookGig(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: gig.color,
                              minimumSize: const Size(74, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm + 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.control,
                                ),
                              ),
                            ),
                            child: Text(
                              'Book',
                              style: AppTypography.button.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _GigDurationPanel extends StatelessWidget {
  final GigOffer gig;
  const _GigDurationPanel({required this.gig});
  @override
  Widget build(BuildContext context) => Container(
      width: 72,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm + 2, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
          color: gig.color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(AppRadius.control)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (gig.popular)
          Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                  color: gig.color, borderRadius: BorderRadius.circular(5)),
              child: Text('POPULAR',
                  style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800))),
        Icon(gig.icon, size: 24, color: gig.color),
        const SizedBox(height: 5),
        Text('2 hr', style: AppTypography.numericMd.copyWith(fontSize: 20)),
        Text('DURATION',
            style: AppTypography.caption.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
      ]));
}

class _PayBadge extends StatelessWidget {
  final GigOffer gig;
  const _PayBadge({required this.gig});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: gig.color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(gig.guaranteedPay,
            style: AppTypography.numericMd.copyWith(color: gig.color)),
        Text('GUARANTEED',
            style: AppTypography.caption.copyWith(
                fontSize: 7.5,
                color: gig.color,
                fontWeight: FontWeight.w800,
                letterSpacing: .55)),
      ]));
}

class _GigTimingPill extends StatelessWidget {
  const _GigTimingPill({required this.gig});

  final GigOffer gig;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 1,
        ),
        decoration: BoxDecoration(
          color: gig.color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.clock3, size: 13, color: gig.color),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                gig.startsAt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: gig.color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
}

class _GigHighlights extends StatelessWidget {
  final GigOffer gig;
  const _GigHighlights({required this.gig});
  @override
  Widget build(BuildContext context) => Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 7),
      decoration: BoxDecoration(
          color: gig.color.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(9)),
      child: Row(children: [
        Expanded(
            child: _GigHighlight(
                icon: LucideIcons.shoppingBag,
                value: '${gig.orders} orders',
                label: 'Expected',
                color: gig.color)),
        Container(
          width: 1,
          height: 28,
          color: gig.color.withValues(alpha: .16),
        ),
        Expanded(
            child: _GigHighlight(
                icon: LucideIcons.zap,
                value: gig.peakBonus,
                label: 'Peak bonus',
                color: gig.color)),
      ]));
}

class _GigHighlight extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _GigHighlight(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(fontSize: 11),
            ),
          ),
        ]),
        const SizedBox(height: 2),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(fontSize: 8.5))
      ]);
}

class _GigMeta extends StatelessWidget {
  final IconData icon;
  final String value;
  const _GigMeta({required this.icon, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Expanded(
            child: Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600)))
      ]);
}
