import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/dashboard/dashboard_stats_model.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../providers/notifications/notifications_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';
import '../../../shared/widgets/navigation/partner_app_header.dart';

/// Scheduled/bookable gig shifts are not backed by any API yet — this
/// screen deliberately shows an honest "coming soon" state rather than
/// fabricated bookings, payouts, or slot counts.
class GigsScreen extends ConsumerWidget {
  const GigsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability =
        ref.watch(dashboardStatsProvider).valueOrNull?.availabilityStatus;
    final unreadNotificationCount = ref
        .watch(notificationsProvider)
        .valueOrNull
        ?.where((notification) => !notification.isRead)
        .length ??
        0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTabScaffold(
        currentIndex: 1,
        child: ResponsiveFrame(
          maxWidth: 680,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.xs,
                  0,
                ),
                child: _GigsHeader(
                  availability: availability,
                  unreadNotificationCount: unreadNotificationCount,
                ),
              ),
              const Expanded(
                child: EmptyState(
                  icon: LucideIcons.calendarClock,
                  title: 'Gig scheduling is coming soon',
                  message:
                      "You'll be able to book fixed-hour gigs and see estimated payouts here once it launches.",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GigsHeader extends StatelessWidget {
  const _GigsHeader({
    this.availability,
    required this.unreadNotificationCount,
  });

  final RiderAvailabilityStatus? availability;
  final int unreadNotificationCount;

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
          final showWordmark = constraints.maxWidth >= 330;

          return Row(
            children: [
              _AvailabilityControl(
                label: statusLabel,
                color: statusColor,
                compact: !showWordmark,
                onTap: () => AppSnackBar.info(
                  context,
                  isOnline
                      ? 'You are online and ready for deliveries.'
                      : 'Go online from the dashboard to start receiving deliveries.',
                ),
              ),
              if (showWordmark) ...[
                const Spacer(),
                const _PartnerWordmark(),
                const Spacer(),
              ] else
                const Spacer(),
              PartnerNotificationButton(
                unreadCount: unreadNotificationCount,
                onPressed: () => Get.toNamed(AppRoutes.notifications),
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
  Widget build(BuildContext context) => const PartnerWordmark();
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => PartnerHeaderIconButton(
        icon: icon,
        label: label,
        onPressed: onTap,
      );
}

@Preview(name: 'Gigs schedule', group: 'Gigs', size: Size(390, 844))
Widget gigsScreenPreview() => const ProviderScope(
      child: MaterialApp(home: GigsScreen()),
    );
