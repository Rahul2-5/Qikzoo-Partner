import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/orders/order_model.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/app_bottom_nav.dart';
import '../views/active_order_view.dart';
import '../views/home_idle_view.dart';
import '../views/order_delivered_view.dart';
import 'incoming_order_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _online = false;
  OrderModel? _order;
  Timer? _incomingTimer;

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
  void dispose() {
    _incomingTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmGoOnline() async {
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Go online?',
      message: 'You will start receiving delivery requests in your area.',
    );
    if (ok == true && mounted) _goOnline();
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
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) =>
            IncomingOrderScreen(order: OrderModel.mock()),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
    if (!mounted) return;
    if (accepted == true) {
      setState(() =>
          _order = OrderModel.mock().copyWith(status: OrderStatus.accepted));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order missed')),
      );
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
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildBody(),
                ),
              ),
              if (showNav) const AppBottomNav(currentIndex: 0),
            ],
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
