import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/orders/order_model.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/navigation/app_bottom_nav.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';
import '../../authentication/widgets/signup_bonus_dialog.dart';
import '../views/active_order_view.dart';
import '../views/home_idle_view.dart';
import '../views/order_delivered_view.dart';
import 'incoming_order_screen.dart';
import 'online_selfie_verification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.showSignupBonus = false,
  });

  final bool showSignupBonus;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _online = false;
  OrderModel? _order;
  Timer? _incomingTimer;
  bool _signupBonusPresented = false;

  static const _statusFlow = {
    OrderStatus.accepted: OrderStatus.navigatingToRestaurant,
    OrderStatus.navigatingToRestaurant: OrderStatus.arrivedAtRestaurant,
    OrderStatus.arrivedAtRestaurant: OrderStatus.pickupConfirmed,
    OrderStatus.pickupConfirmed: OrderStatus.arrivedAtCustomer,
    OrderStatus.arrivedAtCustomer: OrderStatus.deliveryConfirmed,
  };

  bool get _hasActiveOrder =>
      _order != null &&
      _order!.status != OrderStatus.deliveryConfirmed &&
      _order!.status != OrderStatus.completed;

  bool get _isDelivered =>
      _order != null && _order!.status == OrderStatus.deliveryConfirmed;

  @override
  void initState() {
    super.initState();
    if (widget.showSignupBonus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_presentSignupBonus());
      });
    }
  }

  Future<void> _presentSignupBonus() async {
    if (!mounted || _signupBonusPresented) return;
    _signupBonusPresented = true;
    await SignupBonusDialog.show(context);
  }

  @override
  void dispose() {
    _incomingTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmGoOnline() async {
    final selfiePath = await Navigator.of(context).push<String>(
      PageRouteBuilder(
        transitionDuration: AppMotion.duration(context, AppMotion.standard),
        reverseTransitionDuration: AppMotion.duration(context, AppMotion.quick),
        pageBuilder: (_, __, ___) => const OnlineSelfieVerificationScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: AppMotion.enter),
          ),
          child: FadeTransition(opacity: animation, child: child),
        ),
      ),
    );
    if (selfiePath == null || !mounted) return;
    _goOnline();
  }

  void _goOnline() {
    setState(() => _online = true);
    _scheduleIncoming();
  }

  void _scheduleIncoming() {
    _incomingTimer?.cancel();
    _incomingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _online && _order == null) _presentIncoming();
    });
  }

  Future<void> _presentIncoming() async {
    final accepted = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: AppMotion.duration(context, AppMotion.standard),
        reverseTransitionDuration: AppMotion.duration(context, AppMotion.quick),
        pageBuilder: (_, __, ___) =>
            IncomingOrderScreen(order: OrderModel.mock()),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: AppMotion.enter)),
          child: child,
        ),
      ),
    );
    if (!mounted) return;
    if (accepted == true) {
      setState(() =>
          _order = OrderModel.mock().copyWith(status: OrderStatus.accepted));
    } else {
      AppSnackBar.warning(context, 'Order missed');
      _scheduleIncoming();
    }
  }

  void _advance() {
    final current = _order;
    if (current == null) return;
    final next = _statusFlow[current.status];
    if (next == null) return;
    setState(() {
      _order = current.copyWith(
        status: next,
        pickedUpAt: next == OrderStatus.pickupConfirmed ? '10:25 AM' : null,
      );
    });
  }

  void _continueAfterDelivery() {
    setState(() => _order = null);
    _scheduleIncoming();
  }

  Future<void> _confirmGoOffline() async {
    if (_hasActiveOrder) {
      await ConfirmationDialog.show(
        context,
        title: 'Finish your delivery',
        message: 'Complete your current order before going offline.',
      );
      return;
    }
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Go offline?',
      message: 'You will stop receiving new delivery requests.',
    );
    if (ok == true && mounted) {
      _incomingTimer?.cancel();
      setState(() => _online = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showNav = !_hasActiveOrder;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F5FF), AppColors.background],
            stops: [0, 0.34],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final expanded = constraints.maxWidth >= 840;
              final horizontalPadding =
                  expanded ? AppSpacing.xl : AppSpacing.md;

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.sm,
                      horizontalPadding,
                      0,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: AppAnimatedSwap(
                            child: _buildBody(),
                          ),
                        ),
                        if (showNav)
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: const AppBottomNav(currentIndex: 0),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isDelivered) {
      return OrderDeliveredView(
        key: const ValueKey('delivered'),
        order: _order!,
        onContinue: _continueAfterDelivery,
      );
    }
    if (_hasActiveOrder) {
      return ActiveOrderView(
        key: ValueKey('active-${_order!.status}'),
        order: _order!,
        onAdvance: _advance,
      );
    }
    return HomeIdleView(
      key: const ValueKey('idle'),
      online: _online,
      onGoOnline: _confirmGoOnline,
      onGoOffline: _confirmGoOffline,
    );
  }
}
