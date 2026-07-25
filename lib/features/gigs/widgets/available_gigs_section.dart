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
  final bool showAll;
  const AvailableGigsSection({super.key, this.showAll = false});

  @override
  Widget build(BuildContext context) {
    final gigs = showAll ? availableGigs : availableGigs.take(2).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(
          title: 'Available Gigs',
          actionLabel: showAll ? null : 'See all',
          onActionTap: () => Get.toNamed(AppRoutes.gigs)),
      const SizedBox(height: AppSpacing.sm),
      for (final gig in gigs) ...[
        GigOfferCard(gig: gig),
        const SizedBox(height: AppSpacing.sm)
      ],
    ]);
  }
}

class GigOfferCard extends StatelessWidget {
  final GigOffer gig;
  const GigOfferCard({super.key, required this.gig});

  void _bookGig(BuildContext context) => AppSnackBar.success(
      context, '${gig.title} reserved. Check your schedule for details.');

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border.withValues(alpha: .8)),
            boxShadow: AppShadows.control),
        // This card sits inside a vertical ListView on Home. Stretching the
        // Row along its unbounded vertical axis prevents Flutter from laying
        // out the dashboard, so the duration panel uses its content height.
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _GigDurationPanel(gig: gig),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(gig.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium
                                .copyWith(fontSize: 16)),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(LucideIcons.mapPin,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                              child: Text(gig.zone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption))
                        ]),
                      ])),
                  const SizedBox(width: AppSpacing.xs),
                  _PayBadge(gig: gig),
                ]),
                const SizedBox(height: AppSpacing.sm),
                _GigBenefits(gig: gig),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [
                  Expanded(
                      child: _GigMeta(
                          icon: LucideIcons.users, value: gig.ridersNeeded)),
                  Expanded(
                      child: _GigMeta(
                          icon: LucideIcons.clock3, value: gig.startsAt)),
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                      height: 34,
                      child: FilledButton(
                          onPressed: () => _bookGig(context),
                          style: FilledButton.styleFrom(
                              backgroundColor: gig.color,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.control))),
                          child: Text('Book',
                              style: AppTypography.button
                                  .copyWith(fontSize: 12)))),
                ]),
              ])),
        ]),
      );
}

class _GigDurationPanel extends StatelessWidget {
  final GigOffer gig;
  const _GigDurationPanel({required this.gig});
  @override
  Widget build(BuildContext context) => Container(
      width: 82,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
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
        Icon(gig.icon, size: 28, color: gig.color),
        const SizedBox(height: 4),
        Text('2', style: AppTypography.numericMd.copyWith(fontSize: 24)),
        Text('HOURS',
            style: AppTypography.caption.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 5),
        Text('GIG DURATION',
            textAlign: TextAlign.center,
            style: AppTypography.caption
                .copyWith(fontSize: 8, fontWeight: FontWeight.w700)),
      ]));
}

class _PayBadge extends StatelessWidget {
  final GigOffer gig;
  const _PayBadge({required this.gig});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
          color: gig.color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(gig.guaranteedPay,
            style: AppTypography.numericMd.copyWith(color: gig.color)),
        const SizedBox(height: 1),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(LucideIcons.badgeCheck, size: 10, color: gig.color),
          const SizedBox(width: 2),
          Text('Guaranteed',
              style: AppTypography.caption.copyWith(
                  fontSize: 8, color: gig.color, fontWeight: FontWeight.w700))
        ]),
      ]));
}

class _GigBenefits extends StatelessWidget {
  final GigOffer gig;
  const _GigBenefits({required this.gig});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
          color: gig.color.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(9)),
      child: Row(children: [
        Expanded(
            child: _Benefit(
                icon: LucideIcons.shoppingBag,
                value: gig.orders,
                label: 'Expected orders',
                color: gig.color)),
        Expanded(
            child: _Benefit(
                icon: LucideIcons.gift,
                value: gig.peakBonus,
                label: gig.peakThreshold,
                color: gig.color)),
        Expanded(
            child: _Benefit(
                icon: LucideIcons.flame,
                value: gig.extraBonus,
                label: 'Peak bonus',
                color: gig.color)),
      ]));
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _Benefit(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(value, style: AppTypography.bodyMedium.copyWith(fontSize: 11))
        ]),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(fontSize: 8))
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
