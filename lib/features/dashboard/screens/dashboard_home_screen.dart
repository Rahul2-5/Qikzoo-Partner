import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
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
import '../../../providers/orders/dispatch_offer_provider.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';
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
  int _onlineTransitionId = 0;
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
    final isStartingShift = !current.isOnlineFacing;
    setState(() => _isTogglingAvailability = true);
    try {
      if (current.isOnlineFacing) {
        await ref.read(dashboardStatsProvider.notifier).goOffline();
      } else {
        await ref.read(dashboardStatsProvider.notifier).goOnline();
      }
      if (isStartingShift && mounted) {
        setState(() => _onlineTransitionId++);
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
    ref.listen(dispatchOfferProvider, _onOfferChanged);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const _DashboardDrawer(),
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
                    child: _DashboardTopBar(riderName: stats.riderName),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppReveal(
                    delay: const Duration(milliseconds: 45),
                    child: _OnlineStatusBanner(
                      isOnline: stats.availabilityStatus.isOnlineFacing,
                      isBusy: _isTogglingAvailability,
                      onlineTransitionId: _onlineTransitionId,
                      onPressed: () =>
                          _onToggleAvailability(stats.availabilityStatus),
                      onHelp: () => Get.toNamed(AppRoutes.support),
                      onEmergency: () => AppSnackBar.error(
                        context,
                        'For urgent help, call local emergency services and contact Qikzoo support.',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppReveal(
                    delay: const Duration(milliseconds: 90),
                    child: _NextGigHero(
                      gig: availableGigs.first,
                      isOnline: stats.availabilityStatus.isOnlineFacing,
                      onPressed: () {
                        if (stats.availabilityStatus.isOnlineFacing) {
                          AppSnackBar.success(
                            context,
                            '${availableGigs.first.title} reserved. Check your schedule for details.',
                          );
                          return;
                        }
                        _onToggleAvailability(stats.availabilityStatus);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppReveal(
                    delay: const Duration(milliseconds: 135),
                    child: _PerformanceSummary(stats: stats),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppReveal(
                    delay: Duration(milliseconds: 180),
                    child: AvailableGigsSection(
                      showAll: true,
                      startIndex: 1,
                      title: 'More gigs',
                      actionLabel: 'See all',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppReveal(
                    delay: Duration(milliseconds: 225),
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
  const _DashboardTopBar({required this.riderName});

  final String riderName;

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

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.78)),
          ),
          child: Builder(
            builder: (context) => IconButton(
              tooltip: 'Open menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(LucideIcons.menu, color: AppColors.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: Semantics(
            header: true,
            label: 'Qikzoo Rider home',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Qikzoo',
                        style: AppTypography.h2.copyWith(fontSize: 18)),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        'PARTNER',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$_greeting, $firstName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.78)),
          ),
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: () => Get.toNamed(AppRoutes.notifications),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(LucideIcons.bell, color: AppColors.textPrimary),
                Positioned(
                  top: -1,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          button: true,
          label: '${riderName.isEmpty ? 'Rider' : riderName} profile',
          child: InkWell(
            onTap: () => Get.toNamed(AppRoutes.profile),
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14344054),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                initial.toUpperCase(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnlineStatusBanner extends StatefulWidget {
  const _OnlineStatusBanner({
    required this.isOnline,
    required this.isBusy,
    required this.onlineTransitionId,
    required this.onPressed,
    required this.onHelp,
    required this.onEmergency,
  });

  final bool isOnline;
  final bool isBusy;
  final int onlineTransitionId;
  final VoidCallback onPressed;
  final VoidCallback onHelp;
  final VoidCallback onEmergency;

  @override
  State<_OnlineStatusBanner> createState() => _OnlineStatusBannerState();
}

class _OnlineStatusBannerState extends State<_OnlineStatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebrationController;

  bool get isOnline => widget.isOnline;
  bool get isBusy => widget.isBusy;
  VoidCallback get onPressed => widget.onPressed;
  VoidCallback get onHelp => widget.onHelp;
  VoidCallback get onEmergency => widget.onEmergency;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _OnlineStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onlineTransitionId != oldWidget.onlineTransitionId &&
        widget.isOnline &&
        !AppMotion.reduceMotion(context)) {
      _celebrationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isOnline
          ? 'You are online and ready to accept gigs'
          : 'You are offline. Turn on availability to accept gigs',
      child: SizedBox(
        height: 82,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: AppMotion.duration(context, AppMotion.emphasized),
                curve: AppMotion.enter,
                constraints: const BoxConstraints(minHeight: 82),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isOnline
                        ? const [Color(0xFF075A32), Color(0xFF063B32)]
                        : const [Color(0xFF182B5B), Color(0xFF101C45)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sheet),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F243C7A),
                      offset: Offset(0, 12),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -42,
                      top: -46,
                      child: Container(
                        width: 142,
                        height: 142,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isOnline
                                  ? const Color(0xFF55E78B)
                                  : AppColors.secondary)
                              .withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                      child: Row(
                        children: [
                          _ShiftStatusIcon(
                            isOnline: isOnline,
                            celebration: _celebrationController,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YOUR SHIFT',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.surface
                                        .withValues(alpha: 0.62),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                AnimatedSwitcher(
                                  duration: AppMotion.duration(
                                    context,
                                    AppMotion.quick,
                                  ),
                                  switchInCurve: AppMotion.enter,
                                  switchOutCurve: AppMotion.exit,
                                  child: Text(
                                    key: ValueKey(isOnline),
                                    isOnline
                                        ? 'You are Online'
                                        : 'You are Offline',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.surface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          if (isBusy)
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: AppColors.surface,
                                strokeWidth: 2.5,
                              ),
                            )
                          else
                            SizedBox(
                              width: 44,
                              height: 36,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Switch(
                                  key: const Key('availability-toggle'),
                                  value: isOnline,
                                  onChanged: (_) => onPressed(),
                                  activeThumbColor: AppColors.surface,
                                  activeTrackColor: const Color(0xFF20B955),
                                  inactiveThumbColor: AppColors.surface,
                                  inactiveTrackColor: const Color(0xFF6675A7),
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
            const SizedBox(width: AppSpacing.sm),
            _HomeUtilityButton(
              icon: LucideIcons.headphones,
              label: 'Help',
              tooltip: 'Help and support',
              onPressed: onHelp,
            ),
            const SizedBox(width: AppSpacing.xs),
            _HomeUtilityButton(
              icon: LucideIcons.siren,
              label: 'SOS',
              tooltip: 'Emergency support',
              isEmergency: true,
              onPressed: onEmergency,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeUtilityButton extends StatelessWidget {
  const _HomeUtilityButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
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
        icon: LucideIcons.wallet,
        color: AppColors.success,
        value: CurrencyFormatter.rupeesPrecise(stats.todaysEarningsPaise / 100),
        label: "Today's earnings",
      ),
      _PerformanceMetric(
        icon: LucideIcons.packageCheck,
        color: AppColors.warning,
        value: '${stats.todaysDeliveries}',
        label: 'Gigs completed',
      ),
      _PerformanceMetric(
        icon: LucideIcons.target,
        color: AppColors.secondary,
        value: stats.acceptanceRatePercent == null
            ? '—'
            : '${stats.acceptanceRatePercent!.toStringAsFixed(0)}%',
        label: 'Acceptance',
      ),
      _PerformanceMetric(
        icon: LucideIcons.star,
        color: const Color(0xFF7C3AED),
        value: stats.rating.toStringAsFixed(1),
        label: 'Your rating',
      ),
    ];

    return Semantics(
      label: "Today's performance summary",
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A101828),
              offset: Offset(0, 6),
              blurRadius: 16,
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
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: Text(
                    "Today's progress",
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 15,
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
                    'LIVE',
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
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 480) {
                  return Row(
                    children: [
                      for (var index = 0; index < metrics.length; index++) ...[
                        Expanded(child: metrics[index]),
                        if (index < metrics.length - 1)
                          Container(
                            width: 1,
                            height: 76,
                            color: AppColors.border,
                          ),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: metrics[0]),
                        Container(
                            width: 1, height: 72, color: AppColors.border),
                        Expanded(child: metrics[1]),
                      ],
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Divider(
                          color: AppColors.border.withValues(alpha: 0.72)),
                    ),
                    Row(
                      children: [
                        Expanded(child: metrics[2]),
                        Container(
                            width: 1, height: 72, color: AppColors.border),
                        Expanded(child: metrics[3]),
                      ],
                    ),
                  ],
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
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label, $value',
        excludeSemantics: true,
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(fontSize: 9.5),
              ),
            ),
          ],
        ),
      );
}

/// Shortcuts kept at the end of Home so the rider can reach frequently used
/// partner tools without leaving the dashboard flow.
class _DashboardQuickAccessTabs extends StatelessWidget {
  const _DashboardQuickAccessTabs();

  static const _tabs = [
    _DashboardQuickAccessTab(
      label: 'Wallet',
      icon: LucideIcons.wallet,
      color: Color(0xFF16A34A),
      route: AppRoutes.wallet,
    ),
    _DashboardQuickAccessTab(
      label: 'Incentives',
      icon: LucideIcons.gift,
      color: Color(0xFFF97316),
      route: AppRoutes.incentives,
    ),
    _DashboardQuickAccessTab(
      label: 'Performance',
      icon: LucideIcons.barChart3,
      color: Color(0xFF2563EB),
      route: AppRoutes.earnings,
    ),
    _DashboardQuickAccessTab(
      label: 'Schedule',
      icon: LucideIcons.calendarDays,
      color: Color(0xFF9333EA),
      route: AppRoutes.gigs,
    ),
    _DashboardQuickAccessTab(
      label: 'Support',
      icon: LucideIcons.headphones,
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
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Your partner tools',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 560
                    ? 5
                    : constraints.maxWidth >= 420
                        ? 3
                        : 2;
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
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final IconData icon;
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
                height: 84,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: tab.color.withValues(alpha: 0.15),
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
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tab.color.withValues(alpha: 0.11),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(tab.icon, size: 16, color: tab.color),
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

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer();

  @override
  Widget build(BuildContext context) => Drawer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qikzoo Rider', style: AppTypography.h1),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your partner workspace',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
                const _DrawerDestination(
                  icon: LucideIcons.home,
                  label: 'Home',
                  route: AppRoutes.dashboard,
                ),
                const _DrawerDestination(
                  icon: LucideIcons.calendarClock,
                  label: 'Gigs',
                  route: AppRoutes.gigs,
                ),
                const _DrawerDestination(
                  icon: LucideIcons.barChart3,
                  label: 'Earnings',
                  route: AppRoutes.earnings,
                ),
                const _DrawerDestination(
                  icon: LucideIcons.user,
                  label: 'Profile',
                  route: AppRoutes.profile,
                ),
              ],
            ),
          ),
        ),
      );
}

class _DrawerDestination extends StatelessWidget {
  const _DrawerDestination({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: AppTypography.bodyMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        onTap: () {
          Navigator.of(context).pop();
          if (Get.currentRoute != route) Get.offAllNamed(route);
        },
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
