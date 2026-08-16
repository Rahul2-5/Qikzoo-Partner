import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/location/location_platform.dart';
import '../../../core/location/rider_background_location_service.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/dashboard/dashboard_stats_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../providers/location/rider_location_provider.dart';
import '../../../providers/location/rider_location_state.dart';
import '../../../providers/notifications/notifications_provider.dart';
import '../../../providers/polling/rider_polling_controller.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';
import '../../../shared/widgets/navigation/partner_app_header.dart';
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

  bool _backgroundLocationGranted = false;
  bool _backgroundCardDismissed = false;
  bool _isRequestingBackgroundPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Idempotent — the timer lives in the provider, not this screen, so it
    // survives every later tab switch instead of dying with this widget.
    // See RiderPollingController's doc comment for why this moved here.
    // Deferred to a post-frame callback because start() mutates the
    // controller's own provider state, and Riverpod disallows modifying a
    // provider synchronously from within another widget's initState (it's
    // still mid-build at that point).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(riderPollingControllerProvider.notifier).start();
    });
    _refreshBackgroundPermissionState();
  }

  Future<void> _refreshBackgroundPermissionState() async {
    final granted =
        await RiderBackgroundLocationService.instance.hasBackgroundPermission();
    if (mounted) setState(() => _backgroundLocationGranted = granted);
  }

  Future<void> _onEnableBackgroundLocation() async {
    if (_isRequestingBackgroundPermission) return;
    setState(() => _isRequestingBackgroundPermission = true);
    final granted = await RiderBackgroundLocationService.instance
        .requestBackgroundPermission();
    if (!mounted) return;
    setState(() {
      _backgroundLocationGranted = granted;
      _isRequestingBackgroundPermission = false;
    });
    final stats = ref.read(dashboardStatsProvider).valueOrNull;
    if (granted && stats?.availabilityStatus == RiderAvailabilityStatus.available) {
      unawaited(RiderBackgroundLocationService.instance.start());
    }
    if (!granted && mounted) {
      AppSnackBar.info(
        context,
        "You'll still receive offers while the app is open — enable it later from here if you change your mind.",
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Dispatch-offer/active-order poll resume/pause is handled by the
    // app-root observer in app.dart via riderPollingControllerProvider —
    // that one fires regardless of which tab is on screen, unlike this
    // widget-scoped observer. This one stays scoped to what genuinely is
    // location-tracking-specific and tied to this screen's own state
    // (background-permission card, GPS tracker's foreground/background
    // classification).
    final tracker = ref.read(riderLocationControllerProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      tracker.setAppBackgrounded(false);
      // Reconciliation against fresh truth happens in [_onStatsChanged],
      // triggered once this refresh resolves — not here, so cold launch
      // (which never sees a `resumed` transition, only this screen's own
      // first build) and every later resume go through the exact same path.
      ref.read(dashboardStatsProvider.notifier).refresh();
      unawaited(_refreshBackgroundPermissionState());
    } else if (state == AppLifecycleState.paused) {
      tracker.setAppBackgrounded(true);
    }
  }

  /// Reacts to every authoritative backend availability read — the initial
  /// fetch on cold launch, a resume-triggered refresh, pull-to-refresh, or
  /// the result of Go Online/Go Offline — and reconciles the on-device GPS
  /// tracker to match it. This is the single place that keeps tracking state
  /// consistent with backend truth; nothing else starts/stops it based on
  /// availability alone.
  ///
  /// Covers process-death self-healing for AVAILABLE *and* BUSY (a rider
  /// mid-delivery still needs live tracking): the on-device tracker always
  /// starts at `idle` on a fresh launch, so without this a rider could look
  /// "Online"/"Busy" in the UI (from the correctly-fetched dashboard stats)
  /// with no ping loop actually running. Also handles the inverse — backend
  /// says OFFLINE (e.g. the stale-presence sweep force-offlined this rider
  /// while the app sat backgrounded) but the local tracker still thinks it's
  /// running — by stopping it, so a dead-server-side rider doesn't keep
  /// burning battery pinging a position nobody is reading.
  void _onStatsChanged(
    AsyncValue<DashboardStatsModel>? previous,
    AsyncValue<DashboardStatsModel> next,
  ) {
    final stats = next.valueOrNull;
    if (stats == null) return;
    final shouldBeTracking =
        stats.availabilityStatus == RiderAvailabilityStatus.available ||
        stats.availabilityStatus == RiderAvailabilityStatus.busy;
    final tracking = ref.read(riderLocationControllerProvider);
    if (shouldBeTracking && !tracking.isTracking) {
      ref.read(riderLocationControllerProvider.notifier).start();
      unawaited(RiderBackgroundLocationService.instance.start());
    } else if (!shouldBeTracking && tracking.isTracking) {
      ref.read(riderLocationControllerProvider.notifier).stop();
      unawaited(RiderBackgroundLocationService.instance.stop());
    }
    unawaited(_refreshBackgroundPermissionState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _goOffline() async {
    if (_isTogglingAvailability) return;
    setState(() => _isTogglingAvailability = true);
    // Stop pinging before the backend transition, not after — a ping that
    // lands mid-transition could otherwise re-add the rider to Redis GEO
    // right as they're being removed from it.
    ref.read(riderLocationControllerProvider.notifier).stop();
    await RiderBackgroundLocationService.instance.stop();
    try {
      await ref.read(dashboardStatsProvider.notifier).goOffline();
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

  Future<void> _goOnline() async {
    if (_isTogglingAvailability) return;

    final tracker = ref.read(riderLocationControllerProvider.notifier);
    final readiness = await tracker.ensureReadyForOnline();
    if (!mounted) return;
    if (readiness != LocationReadiness.ready) {
      await _showLocationBlockedDialog(readiness);
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
    if (selfieCaptured != true || !mounted) return;

    setState(() => _isTogglingAvailability = true);
    try {
      // 1. A real GPS fix before anything is reported as "online" — never
      //    fabricate a position just to satisfy the flow.
      final position = await tracker.acquireInitialFix();
      if (!mounted) return;
      if (position == null) {
        AppSnackBar.error(
          context,
          "Couldn't get your location. Please try again.",
        );
        return;
      }
      // 2. ONLINE (existing endpoint, unchanged semantics).
      await ref.read(dashboardStatsProvider.notifier).goOnline();
      // 3. Send that first fix so the backend has a last-known position
      //    before the AVAILABLE transition below — RiderAvailabilityService
      //    only mirrors a rider into Redis GEO on AVAILABLE if
      //    Rider.lastLat/lastLng are already set at that moment.
      await tracker.sendImmediateFix(position);
      // 4. AVAILABLE — the transition that actually makes the rider
      //    dispatch-eligible. Existing endpoint, never called by this app
      //    before this change.
      await ref.read(dashboardStatsProvider.notifier).goAvailable();
      // 5. Only now start the continuous ping loop and reflect "online" —
      //    at every earlier step, a failure leaves the rider genuinely
      //    offline rather than showing a false "Online".
      tracker.start();
      // 6. Background tracking (P0-2) is a silent enhancement here, never
      //    a blocker — it only actually starts if the rider already
      //    granted "Allow all the time" location on a previous visit to
      //    the dashboard's opt-in card; otherwise this is a fast no-op and
      //    foreground-only tracking continues to work correctly.
      unawaited(RiderBackgroundLocationService.instance.start());
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        tracker.stop();
        await ref.read(authSessionProvider.notifier).logout();
        if (!mounted) return;
        Get.offAllNamed(AppRoutes.welcome);
        return;
      }
      tracker.stop();
      await _rollbackToOffline();
      if (mounted) AppSnackBar.error(context, e.message);
    } catch (_) {
      tracker.stop();
      await _rollbackToOffline();
      if (mounted) {
        AppSnackBar.error(context, 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isTogglingAvailability = false);
    }
  }

  /// Best-effort: if ONLINE succeeded but a later step (send-location,
  /// AVAILABLE) failed, put the rider back to OFFLINE server-side rather
  /// than leaving them stuck ONLINE-but-not-dispatchable with no ping
  /// loop. If even this fails, the next stats refresh/pull-to-refresh
  /// still reconciles the UI to whatever the server's real state is —
  /// this never fabricates a successful outcome.
  Future<void> _rollbackToOffline() async {
    await RiderBackgroundLocationService.instance.stop();
    try {
      await ref.read(dashboardStatsProvider.notifier).goOffline();
    } catch (_) {
      // See doc comment above.
    }
  }

  Future<void> _showLocationBlockedDialog(LocationReadiness readiness) async {
    late final String title;
    late final String message;
    String? actionLabel;
    Future<void> Function()? action;

    final platform = ref.read(locationPlatformProvider);
    switch (readiness) {
      case LocationReadiness.servicesDisabled:
        title = 'Turn on location';
        message =
            'Location services are off on this device. Dispatch needs your live location to send you delivery offers — turn it on to go online.';
        actionLabel = 'Open location settings';
        action = platform.openLocationSettings;
      case LocationReadiness.permissionDeniedForever:
        title = 'Location permission needed';
        message =
            'Location access is permanently denied for Qikzoo Delivery Partner. Enable it from Settings to go online.';
        actionLabel = 'Open app settings';
        action = platform.openAppSettings;
      case LocationReadiness.permissionDenied:
        title = 'Location permission needed';
        message =
            'Qikzoo Delivery Partner needs your location to send you nearby delivery offers. Please allow location access to go online.';
      case LocationReadiness.ready:
        return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          if (actionLabel != null && action != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                action!();
              },
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  Future<void> _onToggleAvailability(RiderAvailabilityStatus current) async {
    if (current == RiderAvailabilityStatus.busy) {
      AppSnackBar.info(
        context,
        'Finish or cancel your active delivery before going offline.',
      );
      return;
    }
    if (current.isOnlineFacing) {
      await _goOffline();
    } else {
      await _goOnline();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final trackingState = ref.watch(riderLocationControllerProvider);
    final unreadNotificationCount = ref
        .watch(notificationsProvider)
        .valueOrNull
        ?.where((notification) => !notification.isRead)
        .length ??
        0;
    // Dispatch-offer detection and active-order sync are handled by
    // riderPollingControllerProvider regardless of which tab is on screen
    // — see its doc comment. This screen only still owns the
    // location-tracking reconciliation below.
    ref.listen(dashboardStatsProvider, _onStatsChanged);

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
                      isRiderBusy:
                          stats.availabilityStatus == RiderAvailabilityStatus.busy,
                      isTogglingAvailability: _isTogglingAvailability,
                      trackingStatus: stats.availabilityStatus ==
                                  RiderAvailabilityStatus.available ||
                              stats.availabilityStatus ==
                                  RiderAvailabilityStatus.busy
                          ? trackingState.status
                          : null,
                      onPressed: () =>
                          _onToggleAvailability(stats.availabilityStatus),
                    ),
                  ),
                  if (stats.availabilityStatus ==
                          RiderAvailabilityStatus.available &&
                      !_backgroundLocationGranted &&
                      !_backgroundCardDismissed) ...[
                    const SizedBox(height: AppSpacing.md),
                    _BackgroundLocationCard(
                      isRequesting: _isRequestingBackgroundPermission,
                      onEnable: _onEnableBackgroundLocation,
                      onDismiss: () =>
                          setState(() => _backgroundCardDismissed = true),
                    ),
                  ],
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

class _OnlineStatusBanner extends StatelessWidget {
  const _OnlineStatusBanner({
    required this.isOnline,
    required this.isRiderBusy,
    required this.isTogglingAvailability,
    required this.onPressed,
    this.trackingStatus,
  });

  final bool isOnline;

  /// True only for the backend's genuine BUSY status (an active delivery) —
  /// distinct from [isOnline], which is also true for ONLINE/AVAILABLE.
  /// Without this, a rider mid-delivery was shown the exact same "You are
  /// Online" banner as one who was simply available and idle — a real,
  /// confirmed-on-device gap (the banner had no BUSY visual state at all,
  /// regardless of how fresh the underlying data was).
  final bool isRiderBusy;

  /// True only while the Go Online/Offline network call is in flight.
  final bool isTogglingAvailability;
  final VoidCallback onPressed;

  /// Non-null only while the backend status is genuinely AVAILABLE — the
  /// on-device GPS/ping-loop health, shown honestly alongside "Online"
  /// rather than assumed from it. Null (e.g. still ONLINE, pre-AVAILABLE,
  /// or offline) renders no location line at all.
  final RiderLocationTrackingStatus? trackingStatus;

  String? get _locationStatusLabel => switch (trackingStatus) {
        RiderLocationTrackingStatus.active => 'Location active',
        RiderLocationTrackingStatus.acquiring => 'Getting your location…',
        RiderLocationTrackingStatus.signalLost =>
          'Location signal lost — offers may be delayed',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final locationLabel = _locationStatusLabel;
    return Semantics(
      label: isRiderBusy
          ? 'You are busy on an active delivery${locationLabel != null ? ', $locationLabel' : ''}'
          : isOnline
              ? 'You are online and ready to accept gigs${locationLabel != null ? ', $locationLabel' : ''}'
              : 'You are offline. Turn on availability to accept gigs',
      child: SizedBox(
        height: 194,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isRiderBusy
                  ? const [Color(0xFFB54708), Color(0xFF7A2E04)]
                  : isOnline
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
                              label: isRiderBusy
                                  ? 'BUSY'
                                  : isOnline
                                      ? 'ONLINE'
                                      : 'PAUSED',
                              emphasized: true,
                              online: isOnline,
                              busy: isRiderBusy,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isRiderBusy
                              ? 'You are Busy'
                              : isOnline
                                  ? 'You are Online'
                                  : 'You are Offline',
                          style: AppTypography.h1.copyWith(
                            color: AppColors.surface,
                            fontSize: 27,
                            letterSpacing: -0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isRiderBusy
                            ? 'On an active delivery'
                            : isOnline
                                ? 'Ready to start receiving gigs'
                                : 'Go online to start receiving gigs',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.surface.withValues(alpha: 0.86),
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                      if (locationLabel != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trackingStatus ==
                                      RiderLocationTrackingStatus.signalLost
                                  ? LucideIcons.mapPinOff
                                  : LucideIcons.mapPin,
                              size: 11,
                              color: AppColors.surface.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                locationLabel,
                                style: AppTypography.caption.copyWith(
                                  color:
                                      AppColors.surface.withValues(alpha: 0.8),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      SizedBox(
                        height: 46,
                        child: FilledButton.icon(
                          key: const Key('availability-toggle'),
                          onPressed:
                              isTogglingAvailability ? null : onPressed,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: isRiderBusy
                                ? AppColors.warning
                                : isOnline
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
                          icon: isTogglingAvailability
                              ? const SizedBox(
                                  height: 17,
                                  width: 17,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(isRiderBusy
                                  ? LucideIcons.navigation
                                  : isOnline
                                      ? LucideIcons.pause
                                      : LucideIcons.power),
                          label: Text(
                            isRiderBusy
                                ? 'On delivery'
                                : isOnline
                                    ? 'Go offline'
                                    : 'Go online',
                            // AppTypography.button is white by default for
                            // primary CTAs. The availability action has a
                            // white surface, so use the matching foreground
                            // colour to keep its state label visible.
                            style: AppTypography.button.copyWith(
                              fontSize: 13,
                              color: isRiderBusy
                                  ? AppColors.warning
                                  : isOnline
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

/// P0-2's opt-in card — shown only while the rider is genuinely AVAILABLE
/// and "Allow all the time" location hasn't been granted yet. Never shown
/// during the go-online flow itself (foreground location is the only
/// requirement to go online at all); this is a separate, dismissible,
/// later-ask for uninterrupted offers while the app is minimized.
class _BackgroundLocationCard extends StatelessWidget {
  const _BackgroundLocationCard({
    required this.isRequesting,
    required this.onEnable,
    required this.onDismiss,
  });

  final bool isRequesting;
  final VoidCallback onEnable;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: const Color(0xFFD8E2FF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.mapPin, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keep receiving offers in the background',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Allow location access all the time so offers can still reach you when the app is minimised.",
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: isRequesting ? null : onEnable,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.control),
                            ),
                          ),
                          child: isRequesting
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Enable'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        onPressed: isRequesting ? null : onDismiss,
                        child: const Text('Not now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Compact at-a-glance shift totals. Online time comes from the backend's
/// authoritative server-side availability history
/// (`stats.onlineSecondsToday`) — never a client-side estimate/timer.
class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard({required this.stats});

  final DashboardStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final onlineTimeLabel = _formatOnlineTime(stats.onlineSecondsToday);
    return Semantics(
        label:
            "Today's progress: ${CurrencyFormatter.rupeesPrecise(stats.todaysEarningsPaise / 100)} earnings, $onlineTimeLabel online, ${stats.todaysDeliveries} trips",
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
                    Expanded(
                      child: _ProgressMetric(
                        icon: LucideIcons.clock3,
                        value: onlineTimeLabel,
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
}

/// Formats a duration in seconds as `"XhYm"` (e.g. `2h 14m`), matching the
/// compact style already used elsewhere on this card.
String _formatOnlineTime(int onlineSecondsToday) {
  final totalMinutes = onlineSecondsToday ~/ 60;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours}h ${minutes}m';
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
          // Scales the icon+label as one unit rather than truncating — the
          // longest label ("Online time") is what overflows this column's
          // ~110px share of the row on narrow screens (RenderFlex overflow),
          // same fix already applied to `value` above.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: color),
                const SizedBox(width: 3),
                Text(
                  label,
                  maxLines: 1,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _ShiftBadge extends StatelessWidget {
  const _ShiftBadge({
    required this.label,
    this.emphasized = false,
    this.online = false,
    this.busy = false,
  });

  final String label;
  final bool emphasized;
  final bool online;

  /// Renders a distinct amber tone instead of the plain green "online"
  /// tone — a rider mid-delivery needs to visually tell that state apart
  /// from simply being available and idle.
  final bool busy;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: emphasized
              ? (busy
                  ? const Color(0xFFFFE8CC)
                  : online
                      ? const Color(0xFFB9F4CC)
                      : const Color(0xFFFFEEF0))
              : AppColors.surface.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: emphasized
                ? (busy
                    ? AppColors.warning
                    : online
                        ? AppColors.success
                        : AppColors.error)
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
