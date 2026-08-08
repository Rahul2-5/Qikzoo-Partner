import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/dashboard/dashboard_stats_model.dart';
import '../../../models/orders/dispatch_offer_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../providers/notifications/notifications_provider.dart';
import '../../../providers/orders/dispatch_offer_provider.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';
import '../../../shared/widgets/navigation/partner_app_header.dart';
import '../../gigs/widgets/available_gigs_section.dart';
import '../../partner_registration/screens/selfie_verification_screen.dart';

/// Rider dashboard home for active partner accounts.
///
/// Availability is the primary action on this screen. While it is mounted,
/// the dashboard polls for a dispatch offer and routes the rider to it as soon
/// as one is assigned.
class DashboardHomeScreen extends ConsumerStatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  ConsumerState<DashboardHomeScreen> createState() =>
      _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends ConsumerState<DashboardHomeScreen>
    with WidgetsBindingObserver {
  bool _isTogglingAvailability = false;
  Timer? _offerPollTimer;
  String? _lastHandledOfferId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startOfferPolling();
  }

  void _startOfferPolling() {
    _offerPollTimer?.cancel();
    _offerPollTimer = Timer.periodic(
      AppConstants.dispatchOfferPollInterval,
      (_) => ref.read(dispatchOfferProvider.notifier).refresh(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(dispatchOfferProvider.notifier).refresh();
      ref.read(dashboardStatsProvider.notifier).refresh();
      _startOfferPolling();
    } else if (state == AppLifecycleState.paused) {
      _offerPollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _offerPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _setAvailability(RiderAvailabilityStatus current) async {
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

  Future<void> _onToggleAvailability(RiderAvailabilityStatus current) async {
    if (current.isOnlineFacing) {
      await _setAvailability(current);
      return;
    }

    final approved = await ConfirmationDialog.show(
      context,
      title: 'Go online?',
      message:
          'Confirm that you are ready to accept deliveries. A quick selfie is required before your shift starts.',
    );
    if (approved != true || !mounted) return;

    final selfieCaptured = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const SelfieVerificationScreen(isOnlineCheck: true),
      ),
    );
    if (selfieCaptured == true && mounted) {
      await _setAvailability(current);
    }
  }

  void _onOfferChanged(
    AsyncValue<DispatchOfferModel?>? previous,
    AsyncValue<DispatchOfferModel?> next,
  ) {
    final offer = next.valueOrNull;
    if (offer == null || offer.id == _lastHandledOfferId) return;
    _lastHandledOfferId = offer.id;
    Get.toNamed(AppRoutes.incomingOffer);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final unreadNotificationCount = ref
        .watch(notificationsProvider)
        .valueOrNull
        ?.where((notification) => !notification.isRead)
        .length ??
        0;
    ref.listen(dispatchOfferProvider, _onOfferChanged);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTabScaffold(
        currentIndex: 0,
        child: ResponsiveFrame(
          maxWidth: 640,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: statsAsync.when(
            loading: () => const PageLoadingShimmer(
              padding: EdgeInsets.only(top: AppSpacing.md),
            ),
            error: (error, _) => _ErrorView(
              message: error is ApiException
                  ? error.message
                  : 'Could not load your dashboard.',
              onRetry: () =>
                  ref.read(dashboardStatsProvider.notifier).refresh(),
            ),
            data: (stats) => RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: () =>
                  ref.read(dashboardStatsProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
                children: [
                  AppReveal(
                    child: _DashboardTopBar(
                      riderName: stats.riderName,
                      unreadNotificationCount: unreadNotificationCount,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppReveal(
                    delay: const Duration(milliseconds: 45),
                    child: _OnlineStatusBanner(
                      isOnline: stats.availabilityStatus.isOnlineFacing,
                      isBusy: _isTogglingAvailability,
                      onPressed: () =>
                          _onToggleAvailability(stats.availabilityStatus),
                    ),
                  ),
                  if (stats.availabilityStatus.isOnlineFacing) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppReveal(
                      delay: const Duration(milliseconds: 75),
                      child: _TodayProgressCard(stats: stats),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppReveal(
                      delay: const Duration(milliseconds: 105),
                      child: _PerformanceSummary(stats: stats),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AppReveal(
                      delay: Duration(milliseconds: 135),
                      child: AvailableGigsSection(
                        showAll: true,
                        title: 'Top opportunities',
                        subtitle:
                            'Shifts selected for you — book before they fill.',
                        actionLabel: 'View all',
                        horizontal: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  const AppReveal(
                    delay: Duration(milliseconds: 180),
                    child: _DashboardQuickAccessTabs(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({
    required this.riderName,
    required this.unreadNotificationCount,
  });

  final String riderName;
  final int unreadNotificationCount;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final initial = riderName.trim().isEmpty ? 'R' : riderName.trim()[0];
    final nameParts = riderName.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isEmpty || nameParts.first.isEmpty
        ? 'Partner'
        : nameParts.first;

    return PartnerAppHeader(
      subtitle: '$_greeting, $firstName',
      unreadNotificationCount: unreadNotificationCount,
      onNotifications: () => Get.toNamed(AppRoutes.notifications),
      trailing: PartnerAvatarAction(
        initials: initial,
        label: '${riderName.isEmpty ? 'Rider' : riderName} profile',
        onPressed: () => Get.toNamed(AppRoutes.profile),
      ),
    );
  }
}

class _DashboardNotificationButton extends StatelessWidget {
  const _DashboardNotificationButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: unreadCount > 0
            ? 'Notifications, $unreadCount unread'
            : 'Notifications',
        child: Tooltip(
          message: unreadCount > 0
              ? '$unreadCount unread notifications'
              : 'Notifications',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: Ink(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      LucideIcons.bell,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 2,
                        right: 1,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 8,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _OnlineStatusBanner extends StatelessWidget {
  const _OnlineStatusBanner({
    required this.isOnline,
    required this.isBusy,
    required this.onPressed,
  });

  final bool isOnline;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isOnline
          ? 'You are online and ready to accept gigs'
          : 'You are offline. Turn on availability to accept gigs',
      child: SizedBox(
        height: 194,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isOnline
                  ? const [Color(0xFF087D48), Color(0xFF064F38)]
                  : AppColors.ctaGradient,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sheet + 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x283F51B5),
                offset: Offset(0, 14),
                blurRadius: 28,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sheet + 4),
            child: Stack(
              children: [
                Positioned(
                  right: -48,
                  top: -64,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface.withValues(alpha: 0.11),
                    ),
                  ),
                ),
                Positioned(
                  right: -12,
                  bottom: -20,
                  child: IgnorePointer(
                    child: Image.asset(
                      AppAssets.riderScooterIndigo3d,
                      width: 210,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 22,
                    top: 16,
                    child: Container(
                      key: const Key('online-status-celebration'),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF55E78B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF55E78B).withValues(
                              alpha: 0.6,
                            ),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    116,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _ShiftBadge(label: 'SHIFT STATUS'),
                            const SizedBox(width: AppSpacing.xs),
                            _ShiftBadge(
                              label: isOnline ? 'ONLINE' : 'PAUSED',
                              emphasized: true,
                              online: isOnline,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isOnline ? 'You are Online' : 'You are Offline',
                          style: AppTypography.h1.copyWith(
                            color: AppColors.surface,
                            fontSize: 27,
                            letterSpacing: -0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isOnline
                            ? 'Ready to start receiving gigs'
                            : 'Go online to start receiving gigs',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.surface.withValues(alpha: 0.86),
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 46,
                        child: FilledButton.icon(
                          key: const Key('availability-toggle'),
                          onPressed: isBusy ? null : onPressed,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: isOnline
                                ? AppColors.success
                                : AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.control),
                            ),
                          ),
                          icon: isBusy
                              ? const SizedBox(
                                  height: 17,
                                  width: 17,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(isOnline
                                  ? LucideIcons.pause
                                  : LucideIcons.power),
                          label: Text(
                            isOnline ? 'Go offline' : 'Go online',
                            // AppTypography.button is white by default for
                            // primary CTAs. The availability action has a
                            // white surface, so use the matching foreground
                            // colour to keep its state label visible.
                            style: AppTypography.button.copyWith(
                              fontSize: 13,
                              color: isOnline
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact at-a-glance shift totals. The dashboard API does not currently
/// expose an accumulated online duration, so the time begins at zero until
/// that field is available from the backend.
class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard({required this.stats});

  final DashboardStatsModel stats;

  @override
  Widget build(BuildContext context) => Semantics(
        label:
            "Today's progress: ${CurrencyFormatter.rupeesPrecise(stats.todaysEarningsPaise / 100)} earnings, 0 hours online, ${stats.todaysDeliveries} trips",
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 3,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A101828),
                offset: Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                "TODAY'S PROGRESS",
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _ProgressMetric(
                        icon: LucideIcons.circleDollarSign,
                        value: CurrencyFormatter.rupeesPrecise(
                          stats.todaysEarningsPaise / 100,
                        ),
                        label: 'Earnings',
                        color: AppColors.success,
                      ),
                    ),
                    const _ProgressDivider(),
                    const Expanded(
                      child: _ProgressMetric(
                        icon: LucideIcons.clock3,
                        value: '0h 0m',
                        label: 'Online time',
                        color: AppColors.primary,
                      ),
                    ),
                    const _ProgressDivider(),
                    Expanded(
                      child: _ProgressMetric(
                        icon: LucideIcons.shoppingBag,
                        value: '${stats.todaysDeliveries}',
                        label: 'Trips',
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _ProgressDivider extends StatelessWidget {
  const _ProgressDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 38,
        color: AppColors.border.withValues(alpha: 0.8),
      );
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTypography.numericMd.copyWith(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );
}

class _ShiftBadge extends StatelessWidget {
  const _ShiftBadge({
    required this.label,
    this.emphasized = false,
    this.online = false,
  });

  final String label;
  final bool emphasized;
  final bool online;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: emphasized
              ? (online ? const Color(0xFFB9F4CC) : const Color(0xFFFFEEF0))
              : AppColors.surface.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: emphasized
                ? (online ? AppColors.success : AppColors.error)
                : AppColors.surface,
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      );
}

// ignore: unused_element
class _HomeUtilityButton extends StatelessWidget {
  const _HomeUtilityButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    // ignore: unused_element_parameter
    this.isEmergency = false,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isEmergency;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: tooltip,
        child: Tooltip(
          message: tooltip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: Ink(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(
                    color: isEmergency
                        ? AppColors.error.withValues(alpha: 0.34)
                        : AppColors.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isEmergency ? AppColors.error : AppColors.primary,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        color:
                            isEmergency ? AppColors.error : AppColors.primary,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// ignore: unused_element
class _ShiftStatusIcon extends StatelessWidget {
  const _ShiftStatusIcon({
    required this.isOnline,
    required this.celebration,
  });

  final bool isOnline;
  final Animation<double> celebration;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 46,
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (isOnline)
              AnimatedBuilder(
                animation: celebration,
                builder: (context, child) {
                  final progress = Curves.easeOut.transform(celebration.value);
                  return IgnorePointer(
                    child: Opacity(
                      opacity: 1 - progress,
                      child: Transform.scale(
                        scale: 0.9 + (progress * 0.7),
                        child: Container(
                          key: const Key('online-status-celebration'),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF58F28C)
                                  .withValues(alpha: 0.75),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.standard),
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (isOnline ? const Color(0xFF2ED573) : AppColors.surface)
                    .withValues(alpha: isOnline ? 0.18 : 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                isOnline ? LucideIcons.zap : LucideIcons.power,
                color: AppColors.surface,
                size: 21,
              ),
            ),
            if (isOnline)
              Positioned(
                right: -2,
                bottom: -2,
                child: AnimatedBuilder(
                  animation: celebration,
                  builder: (context, child) => Transform.scale(
                    scale: 0.65 +
                        (0.35 *
                            Curves.easeOutBack.transform(
                              celebration.value,
                            )),
                    child: child,
                  ),
                  child: Container(
                    width: 17,
                    height: 17,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF35C96A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      size: 11,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// The first open gig gets the visual priority of a dispatch card while the
/// complete list remains directly below it. This keeps booking a gig as the
/// focal action without turning Home into a second Gigs tab.
// ignore: unused_element
class _NextGigHero extends StatelessWidget {
  const _NextGigHero({
    required this.gig,
    required this.isOnline,
    required this.onPressed,
  });

  final GigOffer gig;
  final bool isOnline;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final artworkWidth = constraints.maxWidth < 370 ? 96.0 : 126.0;

          return Semantics(
            button: true,
            label: isOnline
                ? 'Next gig near you, ${gig.title}, ${gig.zone}, guaranteed ${gig.guaranteedPay}'
                : 'Next gig near you. Go online to book ${gig.title}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(AppRadius.sheet),
                child: Ink(
                  height: 260,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5FCF7),
                    borderRadius: BorderRadius.circular(AppRadius.sheet),
                    border: Border.all(color: const Color(0xFFBDE8CB)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12246B3E),
                        offset: Offset(0, 12),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: -30,
                        top: -36,
                        child: Container(
                          width: 176,
                          height: 176,
                          decoration: const BoxDecoration(
                            color: Color(0x1821B956),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 38,
                        child: IgnorePointer(
                          child: _GigBagArtwork(width: artworkWidth),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          artworkWidth + AppSpacing.md + 4,
                          AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs + 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE641),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.control),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1F9F8B00),
                                    offset: Offset(0, 3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Text(
                                'NEXT GIG NEAR YOU',
                                style: AppTypography.caption.copyWith(
                                  color: const Color(0xFF3A3300),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.65,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm + 3),
                            Text(
                              gig.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.h1.copyWith(
                                fontSize: 22,
                                letterSpacing: -0.55,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs + 1),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.mapPin,
                                  size: 15,
                                  color: gig.color,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    gig.zone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm + 3),
                            _GigTimingPill(
                              icon: LucideIcons.clock3,
                              label: gig.startsAt,
                              color: gig.color,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'GUARANTEED',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.85,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        gig.guaranteedPay,
                                        style: AppTypography.numericMd.copyWith(
                                          color: gig.color,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                FilledButton(
                                  onPressed: onPressed,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 46),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                    backgroundColor: isOnline
                                        ? gig.color
                                        : AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.control,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isOnline ? 'Book gig' : 'Go online',
                                        style: AppTypography.button.copyWith(
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      const Icon(
                                        LucideIcons.arrowRight,
                                        size: 15,
                                      ),
                                    ],
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
              ),
            ),
          );
        },
      );
}

class _GigTimingPill extends StatelessWidget {
  const _GigTimingPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 1,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
}

/// A lightweight parcel illustration keeps the hero expressive without an
/// external image asset or a network dependency.
class _GigBagArtwork extends StatelessWidget {
  const _GigBagArtwork({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: width * 1.08,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              bottom: 4,
              child: Transform.rotate(
                angle: -0.13,
                child: _ParcelBag(
                  width: width * 0.53,
                  height: width * 0.72,
                  color: const Color(0xFFB97A3E),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Transform.rotate(
                angle: 0.10,
                child: _ParcelBag(
                  width: width * 0.68,
                  height: width * 0.82,
                  color: const Color(0xFFD49A56),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: width * 0.25,
              child: const Icon(
                LucideIcons.sparkles,
                size: 16,
                color: Color(0xFFF1BC2E),
              ),
            ),
          ],
        ),
      );
}

class _ParcelBag extends StatelessWidget {
  const _ParcelBag({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(width * 0.16),
            topRight: Radius.circular(width * 0.16),
            bottomLeft: Radius.circular(width * 0.08),
            bottomRight: Radius.circular(width * 0.08),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x263A2109),
              offset: Offset(0, 8),
              blurRadius: 10,
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: width * 0.18,
            height: width * 0.18,
            margin: EdgeInsets.only(top: width * 0.18),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFDF6E7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.packageCheck,
              size: width * 0.1,
              color: AppColors.success,
            ),
          ),
        ),
      );
}

class _PerformanceSummary extends StatelessWidget {
  const _PerformanceSummary({required this.stats});

  final DashboardStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _PerformanceMetric(
        assetPath: AppAssets.profileEarningsWallet3d,
        value: CurrencyFormatter.rupeesPrecise(stats.todaysEarningsPaise / 100),
        label: 'Earnings',
        detail: 'Today',
        cardColor: const Color(0xFFF1FBF4),
        valueColor: AppColors.success,
      ),
      _PerformanceMetric(
        assetPath: AppAssets.dashboardGigsCompleted3d,
        value: '${stats.todaysDeliveries}',
        label: 'Gigs Completed',
        detail: 'Today',
        cardColor: const Color(0xFFFFF7F0),
        valueColor: AppColors.textPrimary,
      ),
      _PerformanceMetric(
        assetPath: AppAssets.dashboardAcceptance3d,
        value: stats.acceptanceRatePercent == null
            ? '—'
            : '${stats.acceptanceRatePercent!.toStringAsFixed(0)}%',
        label: 'Acceptance',
        detail: 'Rate',
        cardColor: const Color(0xFFF2F6FF),
        valueColor: AppColors.textPrimary,
      ),
      _PerformanceMetric(
        assetPath: AppAssets.dashboardRating3d,
        value: stats.rating.toStringAsFixed(1),
        label: 'Rating',
        detail: 'Out of 5',
        cardColor: const Color(0xFFF8F2FF),
        valueColor: AppColors.textPrimary,
      ),
    ];

    return Semantics(
      label: "Today's performance summary",
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A101828),
              offset: Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.barChart3,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: Text(
                    "Today's Overview",
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    '●  Live Data',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.65,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 300) {
                  return Row(
                    children: [
                      for (var index = 0; index < metrics.length; index++) ...[
                        Expanded(child: metrics[index]),
                        if (index < metrics.length - 1)
                          const SizedBox(width: AppSpacing.sm),
                      ],
                    ],
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var index = 0; index < metrics.length; index++) ...[
                        SizedBox(width: 104, child: metrics[index]),
                        if (index < metrics.length - 1)
                          const SizedBox(width: AppSpacing.sm),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  const _PerformanceMetric({
    required this.assetPath,
    required this.value,
    required this.label,
    required this.detail,
    required this.cardColor,
    required this.valueColor,
  });

  final String assetPath;
  final String value;
  final String label;
  final String detail;
  final Color cardColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label, $value',
        excludeSemantics: true,
        child: Container(
          height: 144,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppRadius.sheet),
          ),
          child: Column(
            children: [
              _DashboardMetricSprite(
                size: 46,
                assetPath: assetPath,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: AppTypography.numericLg.copyWith(
                    color: valueColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Crops an icon from the generated 2 × 2 metric sprite without needing four
/// nearly identical bitmap files in the app bundle.
class _DashboardMetricSprite extends StatelessWidget {
  const _DashboardMetricSprite({
    required this.size,
    required this.assetPath,
  });

  final double size;
  final String assetPath;

  @override
  Widget build(BuildContext context) => Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      );
}

/// Crops one of the five generated quick-access objects from a single source
/// image. Keeping the source together makes their 3D lighting consistent.
class _DashboardQuickAccessSprite extends StatelessWidget {
  const _DashboardQuickAccessSprite({
    required this.size,
    required this.assetPath,
  });

  final double size;
  final String assetPath;

  @override
  Widget build(BuildContext context) => Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      );
}

/// Shortcuts kept at the end of Home so the rider can reach frequently used
/// partner tools without leaving the dashboard flow.
class _DashboardQuickAccessTabs extends StatelessWidget {
  const _DashboardQuickAccessTabs();

  static const _tabs = [
    _DashboardQuickAccessTab(
      label: 'Wallet',
      assetPath: AppAssets.profileEarningsWallet3d,
      color: Color(0xFF16A34A),
      route: AppRoutes.wallet,
    ),
    _DashboardQuickAccessTab(
      label: 'Incentives',
      assetPath: AppAssets.dashboardIncentives3d,
      color: Color(0xFFF97316),
      route: AppRoutes.incentives,
    ),
    _DashboardQuickAccessTab(
      label: 'Performance',
      assetPath: AppAssets.dashboardPerformance3d,
      color: Color(0xFF2563EB),
      route: AppRoutes.earnings,
    ),
    _DashboardQuickAccessTab(
      label: 'Schedule',
      assetPath: AppAssets.dashboardSchedule3d,
      color: Color(0xFF9333EA),
      route: AppRoutes.gigs,
    ),
    _DashboardQuickAccessTab(
      label: 'Support',
      assetPath: AppAssets.profileHelpHeadset3d,
      color: Color(0xFF14B8A6),
      route: AppRoutes.support,
    ),
  ];

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Quick access',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Quick access',
                  style: AppTypography.h2.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 340 ? 5 : 3;
                const gap = AppSpacing.sm;
                final itemWidth =
                    (constraints.maxWidth - (gap * (columns - 1))) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final tab in _tabs)
                      SizedBox(
                        width: itemWidth,
                        child: _QuickAccessTabTile(tab: tab),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class _DashboardQuickAccessTab {
  const _DashboardQuickAccessTab({
    required this.label,
    required this.assetPath,
    required this.color,
    required this.route,
  });

  final String label;
  final String assetPath;
  final Color color;
  final String route;
}

class _QuickAccessTabTile extends StatelessWidget {
  const _QuickAccessTabTile({required this.tab});

  final _DashboardQuickAccessTab tab;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: tab.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('quick-access-${tab.label.toLowerCase()}'),
            onTap: () => Get.toNamed(tab.route),
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: AppPressEffect(
              pressedScale: 0.97,
              child: Ink(
                height: 112,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: tab.color.withValues(alpha: 0.075),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: tab.color.withValues(alpha: 0.08),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D101828),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DashboardQuickAccessSprite(
                      size: 52,
                      assetPath: tab.assetPath,
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tab.label,
                        maxLines: 1,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
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
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

@Preview(
  name: 'Home dashboard',
  group: 'Dashboard',
  size: Size(390, 844),
)
Widget dashboardHomeScreenPreview() => const DashboardHomeScreen();
