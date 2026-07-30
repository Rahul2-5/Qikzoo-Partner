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
import '../../../shared/widgets/navigation/app_bottom_nav.dart';
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
    ref.listen(dispatchOfferProvider, _onOfferChanged);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const _DashboardDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
                        _DashboardTopBar(riderName: stats.riderName),
                        const SizedBox(height: AppSpacing.md),
                        _OnlineStatusBanner(
                          isOnline: stats.availabilityStatus.isOnlineFacing,
                          isBusy: _isTogglingAvailability,
                          onPressed: () =>
                              _onToggleAvailability(stats.availabilityStatus),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _PerformanceSummary(stats: stats),
                        const SizedBox(height: AppSpacing.lg),
                        const AvailableGigsSection(showAll: true),
                        const SizedBox(height: AppSpacing.lg),
                        const _DashboardQuickAccessTabs(),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const AppBottomNav(currentIndex: 0),
          ],
        ),
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({required this.riderName});

  final String riderName;

  @override
  Widget build(BuildContext context) {
    final initial = riderName.trim().isEmpty ? 'R' : riderName.trim()[0];

    return Row(
      children: [
        Builder(
          builder: (context) => IconButton(
            tooltip: 'Open menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(LucideIcons.menu, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Semantics(
            header: true,
            label: 'Qikzoo Rider home',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: AppColors.ctaGradient),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Text(
                    'Q',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Qikzoo',
                        style: AppTypography.h2.copyWith(fontSize: 20)),
                    Text(
                      'RIDER',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        IconButton(
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
                border: Border.all(color: AppColors.surface, width: 2),
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
      child: Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF142457), Color(0xFF0B1741)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline
                    ? const Color(0xFF26C65B)
                    : const Color(0xFFABB5D3),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? 'You are Online' : 'You are Offline',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.surface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOnline
                        ? 'Ready to accept gigs'
                        : 'Go online when you are ready',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
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
              Switch(
                key: const Key('availability-toggle'),
                value: isOnline,
                onChanged: (_) => onPressed(),
                activeThumbColor: AppColors.surface,
                activeTrackColor: const Color(0xFF20B955),
                inactiveThumbColor: AppColors.surface,
                inactiveTrackColor: const Color(0xFF6675A7),
              ),
          ],
        ),
      ),
    );
  }
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
        ),
        child: Row(
          children: [
            for (var index = 0; index < metrics.length; index++) ...[
              Expanded(child: metrics[index]),
              if (index < metrics.length - 1)
                Container(width: 1, height: 76, color: AppColors.border),
            ],
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
        child: Row(
          children: [
            for (var index = 0; index < _tabs.length; index++) ...[
              Expanded(child: _QuickAccessTabTile(tab: _tabs[index])),
              if (index < _tabs.length - 1) const SizedBox(width: 6),
            ],
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
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: Ink(
              height: 92,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D101828),
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tab.icon, size: 29, color: tab.color),
                  const SizedBox(height: 7),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tab.label,
                      maxLines: 1,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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
