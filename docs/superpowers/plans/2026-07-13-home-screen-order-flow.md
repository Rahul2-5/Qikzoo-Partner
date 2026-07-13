# Home Screen & Active Order Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the 57KB `dashboard_screen.dart` monolith into a slim shell plus focused view/widget files, and upgrade the Home + active-order UX to production level (full-screen incoming-order takeover with countdown ring, swipe-to-confirm for money actions, animated progress tracker, stylized map).

**Architecture:** A single stateful `DashboardScreen` shell owns all mock state (online flag, current `OrderModel`, `OrderStatus`, the simulation `Timer`) and swaps between five body views via `AnimatedSwitcher`. The incoming-order state is a pushed full-screen route returning a bool. Everything below the shell is a stateless (or self-contained stateful) presentational widget fed by constructor params and callbacks. No providers, no repositories, no network — pure mock UI.

**Tech Stack:** Flutter, `get` (routing/navigation already in project), `lucide_icons`, `equatable`, `google_fonts` (via existing `AppTypography`). No new packages.

## Global Constraints

- Package name for imports in tests: `delivery_partner_app`.
- Use existing design tokens only: `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`. No hardcoded hex/size literals except inside `CustomPainter` geometry.
- Reuse existing shared widgets: `PrimaryCtaButton`, `OutlinedButtonCustom`, `ConfirmationDialog`, `ResponsiveFrame`, `StatusChip`, `FloatingBottomNav`, `EarningsBreakdownWidget`, `CurrencyFormatter`.
- Every screen/view wrapped in `SafeArea` + `ResponsiveFrame(maxWidth: 520)`.
- Primary CTAs use `PrimaryCtaButton` (54dp tall). Icon-only buttons get `Semantics(label:)` or `tooltip`.
- All `AnimationController`s and `Timer`s disposed in `dispose()`.
- Currency shown as `CurrencyFormatter.rupees(...)` where whole rupees; the `.50` paise values in mockups use a new `CurrencyFormatter.rupeesPrecise(...)` added in Task 1.
- No route churn: keep the existing `/dashboard` route. The incoming-order screen is pushed with `Navigator.of(context).push`, not a named route.
- Tests live under `frontend/test/features/dashboard/` mirroring `lib/` structure, using `flutter_test`. Widget-under-test tests wrap the widget in `MaterialApp` + `Scaffold`; screen tests use `GetMaterialApp` like existing screen tests. Use the `setTallSurface` helper pattern (physical size 400x1400) to avoid overflow in tests.

---

## File structure

```
frontend/lib/
  models/orders/order_model.dart                 # MODIFY: enrich with display fields + mock factory + OrderItem
  core/utils/currency_formatter.dart             # MODIFY: add rupeesPrecise()
  features/dashboard/
    screens/
      dashboard_screen.dart                      # REWRITE: slim shell (Task 12)
      incoming_order_screen.dart                 # CREATE (Task 9)
    views/
      home_idle_view.dart                        # CREATE (Task 8)
      active_order_view.dart                     # CREATE (Task 10)
      order_delivered_view.dart                  # CREATE (Task 11)
    widgets/
      map_preview.dart                           # CREATE (Task 2)
      order_progress_tracker.dart                # CREATE (Task 3)
      accept_countdown_ring.dart                 # CREATE (Task 4)
      swipe_action_button.dart                   # CREATE (Task 5)
      greeting_header.dart                       # CREATE (Task 6)
      todays_earnings_card.dart                  # CREATE (Task 6)
      stat_tile_row.dart                         # CREATE (Task 6)
      offline_hero_card.dart                     # CREATE (Task 6)
      waiting_for_orders_card.dart               # CREATE (Task 6)
      order_details_card.dart                    # CREATE (Task 7)
      customer_location_card.dart                # CREATE (Task 7)
      earnings_strip.dart                        # CREATE (Task 7)
      delivery_success_card.dart                 # CREATE (Task 11)
      rating_selector.dart                       # CREATE (Task 11)
      incentive_progress_card.dart               # CREATE (Task 11)
frontend/test/features/dashboard/
  ... mirrored test files ...
```

---

### Task 1: Enrich OrderModel + currency helper

**Files:**
- Modify: `frontend/lib/models/orders/order_model.dart`
- Modify: `frontend/lib/core/utils/currency_formatter.dart`
- Test: `frontend/test/models/orders/order_model_test.dart`

**Interfaces:**
- Produces:
  - `class OrderItem { final String name; final int quantity; }` with `const OrderItem({required name, required quantity})`.
  - `OrderModel` gains fields: `String restaurantArea`, `String dropPincode`, `double pickupDistanceKm`, `int etaMinutes`, `List<OrderItem> items`, `String? customerNote`, `String? pickedUpAt`, `double deliveryFee`, `double distancePay`, `double incentive`.
  - `factory OrderModel.mock()` returns the canonical sample order.
  - `String get itemsSummary` → e.g. `"1 x Chicken Biryani, 1 x Raita, 1 x Coke"`.
  - `int get itemCount` → sum of quantities.
  - `CurrencyFormatter.rupeesPrecise(num)` → `"₹38.50"` (two decimals).

- [ ] **Step 1: Write the failing test**

Create `frontend/test/models/orders/order_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/orders/order_model.dart';
import 'package:delivery_partner_app/core/utils/currency_formatter.dart';

void main() {
  test('OrderModel.mock has consistent earnings breakdown', () {
    final order = OrderModel.mock();
    expect(order.deliveryFee + order.distancePay + order.incentive,
        closeTo(order.amount, 0.001));
    expect(order.amount, 38.50);
  });

  test('itemsSummary and itemCount derive from items', () {
    final order = OrderModel.mock();
    expect(order.itemCount, 3);
    expect(order.itemsSummary, '1 x Chicken Biryani, 1 x Raita, 1 x Coke');
  });

  test('copyWith updates status and pickedUpAt only', () {
    final order = OrderModel.mock();
    final updated =
        order.copyWith(status: OrderStatus.pickupConfirmed, pickedUpAt: '10:25 AM');
    expect(updated.status, OrderStatus.pickupConfirmed);
    expect(updated.pickedUpAt, '10:25 AM');
    expect(updated.id, order.id);
    expect(updated.amount, order.amount);
  });

  test('rupeesPrecise renders two decimals', () {
    expect(CurrencyFormatter.rupeesPrecise(38.5), '₹38.50');
    expect(CurrencyFormatter.rupeesPrecise(920.5), '₹920.50');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/models/orders/order_model_test.dart`
Expected: FAIL — `OrderItem` / `OrderModel.mock` / `rupeesPrecise` not defined.

- [ ] **Step 3: Add `rupeesPrecise` to the formatter**

Replace `frontend/lib/core/utils/currency_formatter.dart` with:

```dart
class CurrencyFormatter {
  CurrencyFormatter._();

  static String rupees(num amount) => '₹${amount.toStringAsFixed(0)}';

  static String rupeesPrecise(num amount) => '₹${amount.toStringAsFixed(2)}';
}
```

- [ ] **Step 4: Rewrite the OrderModel**

Replace `frontend/lib/models/orders/order_model.dart` with:

```dart
import 'package:equatable/equatable.dart';

enum OrderStatus {
  waitingForOrders,
  incomingRequest,
  accepted,
  navigatingToRestaurant,
  arrivedAtRestaurant,
  pickupConfirmed,
  navigatingToCustomer,
  arrivedAtCustomer,
  deliveryConfirmed,
  completed,
}

class OrderItem extends Equatable {
  final String name;
  final int quantity;

  const OrderItem({required this.name, required this.quantity});

  @override
  List<Object?> get props => [name, quantity];
}

class OrderModel extends Equatable {
  final String id;
  final String restaurantName;
  final String restaurantArea;
  final String customerName;
  final String pickupAddress;
  final String dropAddress;
  final String dropPincode;
  final OrderStatus status;
  final double amount;
  final double distanceKm;
  final double pickupDistanceKm;
  final int etaMinutes;
  final List<OrderItem> items;
  final String? customerNote;
  final String? pickedUpAt;
  final double deliveryFee;
  final double distancePay;
  final double incentive;

  const OrderModel({
    required this.id,
    required this.restaurantName,
    required this.restaurantArea,
    required this.customerName,
    required this.pickupAddress,
    required this.dropAddress,
    required this.dropPincode,
    required this.status,
    required this.amount,
    required this.distanceKm,
    required this.pickupDistanceKm,
    required this.etaMinutes,
    required this.items,
    required this.customerNote,
    required this.pickedUpAt,
    required this.deliveryFee,
    required this.distancePay,
    required this.incentive,
  });

  factory OrderModel.mock() => const OrderModel(
        id: '#171287364912',
        restaurantName: 'The Biryani House',
        restaurantArea: 'Goregaon West, Mumbai',
        customerName: 'Rahul Sharma',
        pickupAddress: 'Goregaon West, Mumbai',
        dropAddress: 'Sundervan Complex, Andheri West, Mumbai, Maharashtra',
        dropPincode: '400058',
        status: OrderStatus.incomingRequest,
        amount: 38.50,
        distanceKm: 4.2,
        pickupDistanceKm: 0.8,
        etaMinutes: 12,
        items: [
          OrderItem(name: 'Chicken Biryani', quantity: 1),
          OrderItem(name: 'Raita', quantity: 1),
          OrderItem(name: 'Coke', quantity: 1),
        ],
        customerNote: 'Please send extra tissues',
        pickedUpAt: null,
        deliveryFee: 30.00,
        distancePay: 6.50,
        incentive: 2.00,
      );

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get itemsSummary =>
      items.map((i) => '${i.quantity} x ${i.name}').join(', ');

  OrderModel copyWith({OrderStatus? status, String? pickedUpAt}) => OrderModel(
        id: id,
        restaurantName: restaurantName,
        restaurantArea: restaurantArea,
        customerName: customerName,
        pickupAddress: pickupAddress,
        dropAddress: dropAddress,
        dropPincode: dropPincode,
        status: status ?? this.status,
        amount: amount,
        distanceKm: distanceKm,
        pickupDistanceKm: pickupDistanceKm,
        etaMinutes: etaMinutes,
        items: items,
        customerNote: customerNote,
        pickedUpAt: pickedUpAt ?? this.pickedUpAt,
        deliveryFee: deliveryFee,
        distancePay: distancePay,
        incentive: incentive,
      );

  @override
  List<Object?> get props => [
        id,
        restaurantName,
        restaurantArea,
        customerName,
        pickupAddress,
        dropAddress,
        dropPincode,
        status,
        amount,
        distanceKm,
        pickupDistanceKm,
        etaMinutes,
        items,
        customerNote,
        pickedUpAt,
        deliveryFee,
        distancePay,
        incentive,
      ];
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd frontend && flutter test test/models/orders/order_model_test.dart`
Expected: PASS (4 tests).

Note: this breaks `dashboard_screen.dart`'s old `const order = OrderModel(...)` literal. That's expected — the monolith is rewritten in Task 12. Do NOT run a full `flutter analyze` yet; scope commands to the files in each task until Task 12.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/models/orders/order_model.dart frontend/lib/core/utils/currency_formatter.dart frontend/test/models/orders/order_model_test.dart
git commit -m "Enrich OrderModel with display fields and mock factory"
```

---

### Task 2: MapPreview (stylized CustomPainter map)

**Files:**
- Create: `frontend/lib/features/dashboard/widgets/map_preview.dart`
- Test: `frontend/test/features/dashboard/widgets/map_preview_test.dart`

**Interfaces:**
- Produces: `MapPreview` — `const MapPreview({double height = 150, bool showRoute = true})`. A rounded, clipped decorative map with a start (restaurant) marker, end (customer) marker, and a dashed route line. Pure `CustomPaint`, no state, no assets.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/dashboard/widgets/map_preview_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/map_preview.dart';

void main() {
  testWidgets('MapPreview renders at the requested height', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: MapPreview(height: 150))),
    ));
    final box = tester.getSize(find.byType(MapPreview));
    expect(box.height, 150);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/dashboard/widgets/map_preview_test.dart`
Expected: FAIL — `map_preview.dart` does not exist.

- [ ] **Step 3: Implement MapPreview**

Create `frontend/lib/features/dashboard/widgets/map_preview.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class MapPreview extends StatelessWidget {
  final double height;
  final bool showRoute;

  const MapPreview({super.key, this.height = 150, this.showRoute = true});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _MapPainter(showRoute: showRoute),
          child: showRoute
              ? const Stack(
                  children: [
                    Align(
                      alignment: Alignment(-0.8, 0.2),
                      child: _MapMarker(
                          icon: LucideIcons.store, color: AppColors.secondary),
                    ),
                    Align(
                      alignment: Alignment(0.82, -0.2),
                      child: _MapMarker(
                          icon: LucideIcons.mapPin, color: AppColors.primary),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _MapMarker({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}

class _MapPainter extends CustomPainter {
  final bool showRoute;
  _MapPainter({required this.showRoute});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFEAF0F6);
    canvas.drawRect(Offset.zero & size, bg);

    // Soft "parks"
    final park = Paint()..color = const Color(0xFFD8EBDA);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 26, park);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.25), 20, park);

    // Roads
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.55),
        Offset(size.width, size.height * 0.42), road);
    canvas.drawLine(Offset(size.width * 0.45, 0),
        Offset(size.width * 0.55, size.height), road);

    if (showRoute) {
      final start = Offset(size.width * 0.1, size.height * 0.6);
      final end = Offset(size.width * 0.9, size.height * 0.4);
      final control = Offset(size.width * 0.5, size.height * 0.15);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      _drawDashedPath(canvas, path,
          Paint()
            ..color = AppColors.secondary
            ..strokeWidth = 3.5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dash = 9.0, gap = 6.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        canvas.drawPath(
            metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.showRoute != showRoute;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/dashboard/widgets/map_preview_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/dashboard/widgets/map_preview.dart frontend/test/features/dashboard/widgets/map_preview_test.dart
git commit -m "Add stylized MapPreview widget"
```

---

### Task 3: OrderProgressTracker

**Files:**
- Create: `frontend/lib/features/dashboard/widgets/order_progress_tracker.dart`
- Test: `frontend/test/features/dashboard/widgets/order_progress_tracker_test.dart`

**Interfaces:**
- Consumes: `OrderStatus` from Task 1.
- Produces: `OrderProgressTracker` — `const OrderProgressTracker({required OrderStatus status})`. Renders three labelled nodes (Restaurant Pickup / On the way / Customer Drop). A completed node shows a check; the active node is highlighted; segments between nodes fill based on phase.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/dashboard/widgets/order_progress_tracker_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/order_progress_tracker.dart';
import 'package:delivery_partner_app/models/orders/order_model.dart';

Widget host(OrderStatus status) => MaterialApp(
      home: Scaffold(
        body: OrderProgressTracker(status: status),
      ),
    );

void main() {
  testWidgets('renders all three stage labels', (tester) async {
    await tester.pumpWidget(host(OrderStatus.accepted));
    expect(find.text('Restaurant'), findsOneWidget);
    expect(find.text('On the way'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
  });

  testWidgets('completed stage index grows with status', (tester) async {
    expect(OrderProgressTracker.stageForStatus(OrderStatus.accepted), 0);
    expect(
        OrderProgressTracker.stageForStatus(OrderStatus.navigatingToCustomer), 1);
    expect(OrderProgressTracker.stageForStatus(OrderStatus.deliveryConfirmed), 2);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/dashboard/widgets/order_progress_tracker_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement OrderProgressTracker**

Create `frontend/lib/features/dashboard/widgets/order_progress_tracker.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/order_model.dart';

class OrderProgressTracker extends StatelessWidget {
  final OrderStatus status;

  const OrderProgressTracker({super.key, required this.status});

  /// 0 = at restaurant, 1 = on the way, 2 = delivered.
  static int stageForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
      case OrderStatus.navigatingToRestaurant:
      case OrderStatus.arrivedAtRestaurant:
        return 0;
      case OrderStatus.pickupConfirmed:
      case OrderStatus.navigatingToCustomer:
      case OrderStatus.arrivedAtCustomer:
        return 1;
      case OrderStatus.deliveryConfirmed:
      case OrderStatus.completed:
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = stageForStatus(status);
    const labels = ['Restaurant', 'On the way', 'Customer'];
    const subs = ['Pick up', '', 'Drop'];
    const icons = [LucideIcons.store, LucideIcons.bike, LucideIcons.mapPin];

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 3; i++) ...[
            _Node(
              icon: icons[i],
              label: labels[i],
              sub: subs[i],
              completed: i < stage,
              active: i == stage,
            ),
            if (i < 2)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: _Segment(filled: i < stage),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool completed;
  final bool active;

  const _Node({
    required this.icon,
    required this.label,
    required this.sub,
    required this.completed,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final on = completed || active;
    final circleColor =
        completed ? AppColors.success : (active ? AppColors.primary : AppColors.surfaceMuted);
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              boxShadow: on ? AppShadows.control : null,
            ),
            child: Icon(
              completed ? LucideIcons.check : icon,
              color: on ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: on ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (sub.isNotEmpty)
            Text(sub,
                textAlign: TextAlign.center, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final bool filled;
  const _Segment({required this.filled});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 3,
      decoration: BoxDecoration(
        color: filled ? AppColors.success : AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/dashboard/widgets/order_progress_tracker_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/dashboard/widgets/order_progress_tracker.dart frontend/test/features/dashboard/widgets/order_progress_tracker_test.dart
git commit -m "Add OrderProgressTracker widget"
```

---

### Task 4: AcceptCountdownRing

**Files:**
- Create: `frontend/lib/features/dashboard/widgets/accept_countdown_ring.dart`
- Test: `frontend/test/features/dashboard/widgets/accept_countdown_ring_test.dart`

**Interfaces:**
- Produces: `AcceptCountdownRing` — `AcceptCountdownRing({required int seconds, required VoidCallback onExpired, double size = 60})`. Animated circular ring that depletes over `seconds`, shows remaining seconds as text, changes color (green → amber < 10s → red < 5s), and calls `onExpired` exactly once at 0. Static `AcceptCountdownRing.colorForRemaining(int remaining)` exposes the threshold logic for testing.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/dashboard/widgets/accept_countdown_ring_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/core/theme/app_colors.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/accept_countdown_ring.dart';

void main() {
  test('colorForRemaining crosses thresholds at 10s and 5s', () {
    expect(AcceptCountdownRing.colorForRemaining(30), AppColors.success);
    expect(AcceptCountdownRing.colorForRemaining(10), AppColors.success);
    expect(AcceptCountdownRing.colorForRemaining(9), AppColors.warning);
    expect(AcceptCountdownRing.colorForRemaining(5), AppColors.warning);
    expect(AcceptCountdownRing.colorForRemaining(4), AppColors.error);
  });

  testWidgets('calls onExpired once after the duration elapses', (tester) async {
    var expired = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AcceptCountdownRing(seconds: 2, onExpired: () => expired++),
      ),
    ));
    expect(expired, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 50));
    expect(expired, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/dashboard/widgets/accept_countdown_ring_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement AcceptCountdownRing**

Create `frontend/lib/features/dashboard/widgets/accept_countdown_ring.dart`:

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AcceptCountdownRing extends StatefulWidget {
  final int seconds;
  final VoidCallback onExpired;
  final double size;

  const AcceptCountdownRing({
    super.key,
    required this.seconds,
    required this.onExpired,
    this.size = 60,
  });

  static Color colorForRemaining(int remaining) {
    if (remaining <= 4) return AppColors.error;
    if (remaining <= 9) return AppColors.warning;
    return AppColors.success;
  }

  @override
  State<AcceptCountdownRing> createState() => _AcceptCountdownRingState();
}

class _AcceptCountdownRingState extends State<AcceptCountdownRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && !_fired) {
          _fired = true;
          widget.onExpired();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        (widget.seconds * (1 - _controller.value)).ceil().clamp(0, widget.seconds);
    final color = AcceptCountdownRing.colorForRemaining(remaining);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _RingPainter(progress: 1 - _controller.value, color: color),
        child: Center(
          child: Text(
            '$remaining',
            style: AppTypography.numericMd.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final track = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/dashboard/widgets/accept_countdown_ring_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/dashboard/widgets/accept_countdown_ring.dart frontend/test/features/dashboard/widgets/accept_countdown_ring_test.dart
git commit -m "Add AcceptCountdownRing widget"
```

---

### Task 5: SwipeActionButton

**Files:**
- Create: `frontend/lib/features/dashboard/widgets/swipe_action_button.dart`
- Test: `frontend/test/features/dashboard/widgets/swipe_action_button_test.dart`

**Interfaces:**
- Produces: `SwipeActionButton` — `const SwipeActionButton({required String label, required VoidCallback onConfirmed, IconData icon = LucideIcons.chevronsRight})`. A full-width track with a draggable thumb; dragging past 85% fires `onConfirmed` once and locks; releasing earlier springs the thumb back.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/dashboard/widgets/swipe_action_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/swipe_action_button.dart';

Widget host(VoidCallback onConfirmed) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: SwipeActionButton(
                label: 'Confirm Pickup', onConfirmed: onConfirmed),
          ),
        ),
      ),
    );

void main() {
  testWidgets('full swipe fires onConfirmed once', (tester) async {
    var count = 0;
    await tester.pumpWidget(host(() => count++));
    await tester.drag(find.byType(SwipeActionButton), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(count, 1);
  });

  testWidgets('short swipe does not fire and springs back', (tester) async {
    var count = 0;
    await tester.pumpWidget(host(() => count++));
    await tester.drag(find.byType(SwipeActionButton), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(count, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/dashboard/widgets/swipe_action_button_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement SwipeActionButton**

Create `frontend/lib/features/dashboard/widgets/swipe_action_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class SwipeActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onConfirmed;
  final IconData icon;

  const SwipeActionButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.icon = LucideIcons.chevronsRight,
  });

  @override
  State<SwipeActionButton> createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<SwipeActionButton> {
  static const double _height = 56;
  static const double _thumb = 48;
  double _dx = 0;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDx = constraints.maxWidth - _thumb - 8;
        final progress = maxDx <= 0 ? 0.0 : (_dx / maxDx).clamp(0.0, 1.0);
        return SizedBox(
          height: _height,
          width: double.infinity,
          child: Stack(
            children: [
              // Track + gradient fill following the thumb.
              Container(
                height: _height,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: _dx + _thumb + 4,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: AppColors.ctaGradient),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: (1 - progress).clamp(0.0, 1.0),
                  child: Text(
                    widget.label,
                    style: AppTypography.button.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              Positioned(
                left: 4 + _dx,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: _confirmed
                      ? null
                      : (d) => setState(
                          () => _dx = (_dx + d.delta.dx).clamp(0.0, maxDx)),
                  onHorizontalDragEnd: _confirmed
                      ? null
                      : (_) {
                          if (progress >= 0.85) {
                            setState(() {
                              _dx = maxDx;
                              _confirmed = true;
                            });
                            HapticFeedback.lightImpact();
                            widget.onConfirmed();
                          } else {
                            setState(() => _dx = 0);
                          }
                        },
                  child: Container(
                    width: _thumb,
                    height: _thumb,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Icon(
                      _confirmed ? LucideIcons.check : widget.icon,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/dashboard/widgets/swipe_action_button_test.dart`
Expected: PASS. (The 300px drag exceeds 85% of the track; the 40px drag springs back.)

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/dashboard/widgets/swipe_action_button.dart frontend/test/features/dashboard/widgets/swipe_action_button_test.dart
git commit -m "Add SwipeActionButton widget"
```

---

### Task 6: Home idle building-block widgets

**Files:**
- Create: `frontend/lib/features/dashboard/widgets/greeting_header.dart`
- Create: `frontend/lib/features/dashboard/widgets/todays_earnings_card.dart`
- Create: `frontend/lib/features/dashboard/widgets/stat_tile_row.dart`
- Create: `frontend/lib/features/dashboard/widgets/offline_hero_card.dart`
- Create: `frontend/lib/features/dashboard/widgets/waiting_for_orders_card.dart`
- Test: `frontend/test/features/dashboard/widgets/home_widgets_test.dart`

**Interfaces:**
- Produces:
  - `GreetingHeader({required bool online, required VoidCallback onToggleStatus})` — logo/greeting row with an Online/Offline status pill (tapping the pill calls `onToggleStatus`) and a Help button.
  - `TodaysEarningsCard({required double amount})` — blue gradient wallet card, "Today's Earnings" + precise rupees.
  - `StatTileRow({required int deliveries, required String hoursOnline, required double rating})` — three mini stat tiles.
  - `OfflineHeroCard({required VoidCallback onGoOnline})` — hero zone + dominant Go Online CTA.
  - `WaitingForOrdersCard()` — animated radar pulse + "Finding orders near you…".

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/dashboard/widgets/home_widgets_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/greeting_header.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/todays_earnings_card.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/stat_tile_row.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/offline_hero_card.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/waiting_for_orders_card.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('GreetingHeader toggle fires callback', (tester) async {
    var toggled = 0;
    await tester.pumpWidget(
        wrap(GreetingHeader(online: false, onToggleStatus: () => toggled++)));
    expect(find.text('Offline'), findsOneWidget);
    await tester.tap(find.text('Offline'));
    expect(toggled, 1);
  });

  testWidgets('TodaysEarningsCard shows precise amount', (tester) async {
    await tester.pumpWidget(wrap(const TodaysEarningsCard(amount: 920.5)));
    expect(find.text('₹920.50'), findsOneWidget);
    expect(find.text("Today's Earnings"), findsOneWidget);
  });

  testWidgets('StatTileRow renders three stats', (tester) async {
    await tester.pumpWidget(wrap(const StatTileRow(
        deliveries: 12, hoursOnline: '4h 30m', rating: 4.8)));
    expect(find.text('12'), findsOneWidget);
    expect(find.text('4h 30m'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
  });

  testWidgets('OfflineHeroCard Go Online fires callback', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(wrap(OfflineHeroCard(onGoOnline: () => pressed++)));
    await tester.tap(find.text('Go Online'));
    expect(pressed, 1);
  });

  testWidgets('WaitingForOrdersCard shows searching copy', (tester) async {
    await tester.pumpWidget(wrap(const WaitingForOrdersCard()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Finding orders near you…'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/dashboard/widgets/home_widgets_test.dart`
Expected: FAIL — files do not exist.

- [ ] **Step 3a: Implement GreetingHeader**

Create `frontend/lib/features/dashboard/widgets/greeting_header.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class GreetingHeader extends StatelessWidget {
  final bool online;
  final VoidCallback onToggleStatus;

  const GreetingHeader({
    super.key,
    required this.online,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('QIKZOO',
            style: AppTypography.h2.copyWith(color: AppColors.primary)),
        const Spacer(),
        GestureDetector(
          onTap: onToggleStatus,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              boxShadow: AppShadows.control,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: online ? AppColors.success : AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(online ? 'Online' : 'Offline',
                    style: AppTypography.bodyMedium),
                const Icon(LucideIcons.chevronDown,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          onPressed: () {},
          tooltip: 'Help',
          icon: const Icon(LucideIcons.helpCircle, color: AppColors.primary),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3b: Implement TodaysEarningsCard**

Create `frontend/lib/features/dashboard/widgets/todays_earnings_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class TodaysEarningsCard extends StatelessWidget {
  final double amount;

  const TodaysEarningsCard({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2C3D8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Icon(LucideIcons.wallet, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Earnings",
                    style: AppTypography.caption.copyWith(color: Colors.white70)),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.rupeesPrecise(amount),
                  style: AppTypography.numericLg.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.white70),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3c: Implement StatTileRow**

Create `frontend/lib/features/dashboard/widgets/stat_tile_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class StatTileRow extends StatelessWidget {
  final int deliveries;
  final String hoursOnline;
  final double rating;

  const StatTileRow({
    super.key,
    required this.deliveries,
    required this.hoursOnline,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _Tile(
                icon: LucideIcons.package,
                value: '$deliveries',
                label: 'Deliveries')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _Tile(
                icon: LucideIcons.clock,
                value: hoursOnline,
                label: 'Online')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _Tile(
                icon: LucideIcons.star,
                value: rating.toStringAsFixed(1),
                label: 'Rating')),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Tile({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.numericMd),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3d: Implement OfflineHeroCard**

Create `frontend/lib/features/dashboard/widgets/offline_hero_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';

class OfflineHeroCard extends StatelessWidget {
  final VoidCallback onGoOnline;

  const OfflineHeroCard({super.key, required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.power,
                color: AppColors.textSecondary, size: 30),
          ),
          const SizedBox(height: AppSpacing.md),
          Text("You're offline", style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Go online to start receiving delivery requests near you.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryCtaButton(
            label: 'Go Online',
            trailingIcon: LucideIcons.arrowRight,
            onPressed: onGoOnline,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3e: Implement WaitingForOrdersCard**

Create `frontend/lib/features/dashboard/widgets/waiting_for_orders_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class WaitingForOrdersCard extends StatefulWidget {
  const WaitingForOrdersCard({super.key});

  @override
  State<WaitingForOrdersCard> createState() => _WaitingForOrdersCardState();
}

class _WaitingForOrdersCardState extends State<WaitingForOrdersCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _pulse(0),
                    _pulse(0.5),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.bike,
                          color: Colors.white, size: 26),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Finding orders near you…', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "You're online. Stay ready — a request can arrive any moment.",
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _pulse(double offset) {
    final t = (_controller.value + offset) % 1.0;
    return Opacity(
      opacity: (1 - t).clamp(0.0, 1.0) * 0.4,
      child: Container(
        width: 60 + t * 60,
        height: 60 + t * 60,
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/dashboard/widgets/home_widgets_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/dashboard/widgets/greeting_header.dart frontend/lib/features/dashboard/widgets/todays_earnings_card.dart frontend/lib/features/dashboard/widgets/stat_tile_row.dart frontend/lib/features/dashboard/widgets/offline_hero_card.dart frontend/lib/features/dashboard/widgets/waiting_for_orders_card.dart frontend/test/features/dashboard/widgets/home_widgets_test.dart
git commit -m "Add home idle building-block widgets"
```

---

### Task 7: Order detail widgets (details card, location card, earnings strip)

**Files:**
- Create: `frontend/lib/features/dashboard/widgets/order_details_card.dart`
- Create: `frontend/lib/features/dashboard/widgets/customer_location_card.dart`
- Create: `frontend/lib/features/dashboard/widgets/earnings_strip.dart`
- Test: `frontend/test/features/dashboard/widgets/order_detail_widgets_test.dart`

**Interfaces:**
- Consumes: `OrderModel` (Task 1), `MapPreview` (Task 2).
- Produces:
  - `OrderDetailsCard({required OrderModel order})` — restaurant row + Call, Order ID row + Copy (writes `Clipboard` and shows a "Order ID copied" `SnackBar`), expandable Order Items, expandable Customer Note (hidden when null/empty).
  - `CustomerLocationCard({required String title, required String address, String? pincode, String? etaLine})` — location header, Navigate button, `MapPreview`, optional ETA/traffic strip.
  - `EarningsStrip({required double amount})` — "Estimated Earning" + precise rupees + "View detail".

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/dashboard/widgets/order_detail_widgets_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/order_details_card.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/customer_location_card.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/earnings_strip.dart';
import 'package:delivery_partner_app/models/orders/order_model.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('OrderDetailsCard copies order id to clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    await tester
        .pumpWidget(wrap(OrderDetailsCard(order: OrderModel.mock())));
    await tester.tap(find.text('Copy'));
    await tester.pump();
    expect(copied, '#171287364912');
    expect(find.text('Order ID copied'), findsOneWidget);
  });

  testWidgets('OrderDetailsCard expands items on tap', (tester) async {
    await tester.pumpWidget(wrap(OrderDetailsCard(order: OrderModel.mock())));
    expect(find.text('1 x Chicken Biryani, 1 x Raita, 1 x Coke'), findsOneWidget);
  });

  testWidgets('EarningsStrip shows precise amount', (tester) async {
    await tester.pumpWidget(wrap(const EarningsStrip(amount: 38.5)));
    expect(find.text('₹38.50'), findsOneWidget);
    expect(find.text('View detail'), findsOneWidget);
  });

  testWidgets('CustomerLocationCard shows address and Navigate', (tester) async {
    await tester.pumpWidget(wrap(const CustomerLocationCard(
      title: 'Customer Location',
      address: 'Sundervan Complex, Andheri West',
      pincode: '400058',
      etaLine: '4.2 km away · 12 mins',
    )));
    expect(find.text('Customer Location'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('4.2 km away · 12 mins'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/dashboard/widgets/order_detail_widgets_test.dart`
Expected: FAIL — files do not exist.

- [ ] **Step 3a: Implement EarningsStrip**

Create `frontend/lib/features/dashboard/widgets/earnings_strip.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class EarningsStrip extends StatelessWidget {
  final double amount;

  const EarningsStrip({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surface,
            child: Icon(LucideIcons.wallet, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estimated Earning', style: AppTypography.caption),
                Text(CurrencyFormatter.rupeesPrecise(amount),
                    style: AppTypography.numericMd),
              ],
            ),
          ),
          Row(
            children: [
              Text('View detail',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.primary)),
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3b: Implement CustomerLocationCard**

Create `frontend/lib/features/dashboard/widgets/customer_location_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'map_preview.dart';

class CustomerLocationCard extends StatelessWidget {
  final String title;
  final String address;
  final String? pincode;
  final String? etaLine;

  const CustomerLocationCard({
    super.key,
    required this.title,
    required this.address,
    this.pincode,
    this.etaLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.mapPin, color: AppColors.success, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      pincode == null ? address : '$address $pincode',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _NavigateButton(onPressed: () {}),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const MapPreview(height: 150),
          if (etaLine != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(LucideIcons.map,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(etaLine!, style: AppTypography.bodyMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NavigateButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _NavigateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(LucideIcons.navigation, size: 16),
      label: const Text('Navigate'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control)),
      ),
    );
  }
}
```

- [ ] **Step 3c: Implement OrderDetailsCard**

Create `frontend/lib/features/dashboard/widgets/order_details_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/order_model.dart';

class OrderDetailsCard extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsCard({super.key, required this.order});

  void _copyId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: order.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order ID copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(LucideIcons.store,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.restaurantName, style: AppTypography.bodyMedium),
                    Text(order.restaurantArea, style: AppTypography.caption),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.phone, size: 16),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.border),
          Row(
            children: [
              const Icon(LucideIcons.clipboard,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ID', style: AppTypography.caption),
                    Text(order.id, style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _copyId(context),
                icon: const Icon(LucideIcons.copy, size: 16),
                label: const Text('Copy'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.border),
          _ExpandableRow(
            icon: LucideIcons.shoppingBasket,
            title: 'Order Items',
            preview: order.itemsSummary,
            detail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: order.items
                  .map((i) => Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text('${i.quantity} x ${i.name}',
                            style: AppTypography.body),
                      ))
                  .toList(),
            ),
          ),
          if (order.customerNote != null &&
              order.customerNote!.isNotEmpty) ...[
            const Divider(height: AppSpacing.lg, color: AppColors.border),
            _ExpandableRow(
              icon: LucideIcons.stickyNote,
              title: 'Note from customer',
              preview: order.customerNote!,
              detail: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(order.customerNote!, style: AppTypography.body),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpandableRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final String preview;
  final Widget detail;

  const _ExpandableRow({
    required this.icon,
    required this.title,
    required this.preview,
    required this.detail,
  });

  @override
  State<_ExpandableRow> createState() => _ExpandableRowState();
}

class _ExpandableRowState extends State<_ExpandableRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTypography.caption),
                    Text(widget.preview,
                        maxLines: _open ? 10 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              Icon(_open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                _open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Align(
                alignment: Alignment.centerLeft, child: widget.detail),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
```

Note: the "expands items on tap" test asserts the preview text (`itemsSummary`) is present, which it always is in the collapsed row — the expand animation is covered by manual/preview inspection. The card shows the summary as the preview line.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/dashboard/widgets/order_detail_widgets_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/dashboard/widgets/order_details_card.dart frontend/lib/features/dashboard/widgets/customer_location_card.dart frontend/lib/features/dashboard/widgets/earnings_strip.dart frontend/test/features/dashboard/widgets/order_detail_widgets_test.dart
git commit -m "Add order detail, location, and earnings widgets"
```

---

### Task 8: HomeIdleView (states A & B)

**Files:**
- Create: `frontend/lib/features/dashboard/views/home_idle_view.dart`
- Test: `frontend/test/features/dashboard/views/home_idle_view_test.dart`

**Interfaces:**
- Consumes: `GreetingHeader`, `TodaysEarningsCard`, `StatTileRow`, `OfflineHeroCard`, `WaitingForOrdersCard` (Task 6).
- Produces: `HomeIdleView({required bool online, required VoidCallback onGoOnline, required VoidCallback onGoOffline})`. Scrollable idle home; shows offline hero when `!online`, waiting card + Go Offline button when `online`.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/dashboard/views/home_idle_view_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/views/home_idle_view.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('offline state shows the offline hero', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(wrap(HomeIdleView(
      online: false,
      onGoOnline: () {},
      onGoOffline: () {},
    )));
    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Go Online'), findsOneWidget);
  });

  testWidgets('online state shows the waiting card and Go Offline',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(wrap(HomeIdleView(
      online: true,
      onGoOnline: () {},
      onGoOffline: () {},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Finding orders near you…'), findsOneWidget);
    expect(find.text('Go Offline'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/dashboard/views/home_idle_view_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement HomeIdleView**

Create `frontend/lib/features/dashboard/views/home_idle_view.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/outlined_button_custom.dart';
import '../widgets/greeting_header.dart';
import '../widgets/offline_hero_card.dart';
import '../widgets/stat_tile_row.dart';
import '../widgets/todays_earnings_card.dart';
import '../widgets/waiting_for_orders_card.dart';

class HomeIdleView extends StatelessWidget {
  final bool online;
  final VoidCallback onGoOnline;
  final VoidCallback onGoOffline;

  const HomeIdleView({
    super.key,
    required this.online,
    required this.onGoOnline,
    required this.onGoOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GreetingHeader(
          online: online,
          onToggleStatus: online ? onGoOffline : onGoOnline,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi, Rahul 👋',
                    style: AppTypography.body.copyWith(fontSize: 16)),
                const SizedBox(height: AppSpacing.xs),
                Text(online ? 'Ready for orders' : 'Ready to deliver?',
                    style: AppTypography.h1.copyWith(fontSize: 26)),
                const SizedBox(height: AppSpacing.lg),
                const TodaysEarningsCard(amount: 920.50),
                const SizedBox(height: AppSpacing.md),
                if (online)
                  const WaitingForOrdersCard()
                else
                  OfflineHeroCard(onGoOnline: onGoOnline),
                const SizedBox(height: AppSpacing.md),
                const StatTileRow(
                    deliveries: 12, hoursOnline: '4h 30m', rating: 4.8),
                const SizedBox(height: AppSpacing.md),
                if (online)
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppSpacing.sm, left: 0, right: 0),
                    child: OutlinedButtonCustom(
                      label: 'Go Offline',
                      onPressed: onGoOffline,
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

Note: `AppColors` import is used indirectly by children; keep the import list as written (analyzer will flag unused imports — remove `app_colors.dart` import if `flutter analyze` reports it unused in this file).

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/dashboard/views/home_idle_view_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/dashboard/views/home_idle_view.dart frontend/test/features/dashboard/views/home_idle_view_test.dart
git commit -m "Add HomeIdleView for offline and waiting states"
```

---

### Task 9: IncomingOrderScreen (state C, full-screen takeover)

**Files:**
- Create: `frontend/lib/features/dashboard/screens/incoming_order_screen.dart`
- Test: `frontend/test/features/dashboard/screens/incoming_order_screen_test.dart`

**Interfaces:**
- Consumes: `OrderModel` (Task 1), `AcceptCountdownRing` (Task 4), `PrimaryCtaButton`, `StatusChip`, `ResponsiveFrame`, `CurrencyFormatter`.
- Produces: `IncomingOrderScreen({required OrderModel order, int seconds = 30})`. A full-screen route. Pops `true` on Accept, `false` on Reject, `false` automatically on countdown expiry.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/dashboard/screens/incoming_order_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/screens/incoming_order_screen.dart';
import 'package:delivery_partner_app/models/orders/order_model.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<bool?> pushScreen(WidgetTester tester, {int seconds = 30}) async {
  bool? result;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => IncomingOrderScreen(
                      order: OrderModel.mock(), seconds: seconds),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('Accept pops true', (tester) async {
    setTallSurface(tester);
    await pushScreen(tester);
    expect(find.text('New Order'), findsOneWidget);
    await tester.tap(find.text('Accept Order'));
    await tester.pumpAndSettle();
    expect(find.text('New Order'), findsNothing);
  });

  testWidgets('Reject pops false', (tester) async {
    setTallSurface(tester);
    await pushScreen(tester);
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    expect(find.text('New Order'), findsNothing);
  });

  testWidgets('expiry auto-dismisses', (tester) async {
    setTallSurface(tester);
    await pushScreen(tester, seconds: 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('New Order'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/dashboard/screens/incoming_order_screen_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement IncomingOrderScreen**

Create `frontend/lib/features/dashboard/screens/incoming_order_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/order_model.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/chips/status_chip.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/accept_countdown_ring.dart';

class IncomingOrderScreen extends StatefulWidget {
  final OrderModel order;
  final int seconds;

  const IncomingOrderScreen({
    super.key,
    required this.order,
    this.seconds = 30,
  });

  @override
  State<IncomingOrderScreen> createState() => _IncomingOrderScreenState();
}

class _IncomingOrderScreenState extends State<IncomingOrderScreen> {
  bool _closed = false;

  void _close(bool accepted) {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop(accepted);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(false);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 520,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                AcceptCountdownRing(
                  seconds: widget.seconds,
                  onExpired: () => _close(false),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('New Order', style: AppTypography.h1),
                    const SizedBox(width: AppSpacing.sm),
                    StatusChip(
                      label: 'New',
                      color: AppColors.warning,
                      background: AppColors.warningBg,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _EarningBlock(amount: order.amount),
                        const SizedBox(height: AppSpacing.md),
                        _RouteBlock(order: order),
                        const SizedBox(height: AppSpacing.md),
                        _MetaRow(order: order),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryCtaButton(
                  label: 'Accept Order',
                  trailingIcon: LucideIcons.chevronsRight,
                  onPressed: () => _close(true),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: () => _close(false),
                  child: Text('Reject',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.error)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EarningBlock extends StatelessWidget {
  final double amount;
  const _EarningBlock({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        children: [
          Text('You earn', style: AppTypography.caption),
          Text(CurrencyFormatter.rupeesPrecise(amount),
              style: AppTypography.display.copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}

class _RouteBlock extends StatelessWidget {
  final OrderModel order;
  const _RouteBlock({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        children: [
          _RouteRow(
            icon: LucideIcons.store,
            color: AppColors.secondary,
            title: order.restaurantName,
            subtitle: order.restaurantArea,
            trailing: '${order.pickupDistanceKm} km',
          ),
          Padding(
            padding: const EdgeInsets.only(left: 21),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 22,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                          color: AppColors.border, width: 2),
                    ),
                  ),
                  child: SizedBox(width: 2),
                ),
              ),
            ),
          ),
          _RouteRow(
            icon: LucideIcons.mapPin,
            color: AppColors.primary,
            title: order.dropAddress,
            subtitle: 'Trip · ${order.distanceKm} km · ${order.etaMinutes} mins',
            trailing: null,
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? trailing;

  const _RouteRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium),
              Text(subtitle, style: AppTypography.caption),
            ],
          ),
        ),
        if (trailing != null)
          Text(trailing!,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final OrderModel order;
  const _MetaRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Chip(
            icon: LucideIcons.shoppingBasket,
            label: '${order.itemCount} items',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Chip(
            icon: LucideIcons.banknote,
            label: 'Prepaid',
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/dashboard/screens/incoming_order_screen_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/dashboard/screens/incoming_order_screen.dart frontend/test/features/dashboard/screens/incoming_order_screen_test.dart
git commit -m "Add IncomingOrderScreen full-screen takeover with countdown"
```

---

### Task 10: ActiveOrderView (state D)

**Files:**
- Create: `frontend/lib/features/dashboard/views/active_order_view.dart`
- Test: `frontend/test/features/dashboard/views/active_order_view_test.dart`

**Interfaces:**
- Consumes: `OrderModel`, `OrderProgressTracker` (Task 3), `SwipeActionButton` (Task 5), `OrderDetailsCard`, `CustomerLocationCard`, `EarningsStrip` (Task 7), `PrimaryCtaButton`, `OutlinedButtonCustom`.
- Produces: `ActiveOrderView({required OrderModel order, required VoidCallback onAdvance})`. Renders the restaurant or customer phase from `order.status`, with the correct sticky bottom CTA. Tap CTAs and swipe CTAs both call `onAdvance`. Exposes `static String ctaLabelFor(OrderStatus)` and `static bool isSwipeStatus(OrderStatus)` for testing/labeling.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/dashboard/views/active_order_view_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/views/active_order_view.dart';
import 'package:delivery_partner_app/models/orders/order_model.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget host(OrderModel order, VoidCallback onAdvance) => MaterialApp(
      home: Scaffold(
        body: ActiveOrderView(order: order, onAdvance: onAdvance),
      ),
    );

void main() {
  test('cta labels map to status', () {
    expect(ActiveOrderView.ctaLabelFor(OrderStatus.accepted),
        'Navigate to Restaurant');
    expect(ActiveOrderView.ctaLabelFor(OrderStatus.navigatingToRestaurant),
        'Reached Restaurant');
    expect(ActiveOrderView.ctaLabelFor(OrderStatus.arrivedAtRestaurant),
        'Confirm Pickup');
    expect(ActiveOrderView.ctaLabelFor(OrderStatus.navigatingToCustomer),
        'Reached Customer');
    expect(ActiveOrderView.ctaLabelFor(OrderStatus.arrivedAtCustomer),
        'Confirm Delivery');
  });

  test('swipe statuses are the two confirm actions', () {
    expect(ActiveOrderView.isSwipeStatus(OrderStatus.arrivedAtRestaurant), true);
    expect(ActiveOrderView.isSwipeStatus(OrderStatus.arrivedAtCustomer), true);
    expect(ActiveOrderView.isSwipeStatus(OrderStatus.accepted), false);
  });

  testWidgets('tap CTA advances', (tester) async {
    setTallSurface(tester);
    var advanced = 0;
    await tester.pumpWidget(host(
        OrderModel.mock().copyWith(status: OrderStatus.accepted),
        () => advanced++));
    await tester.tap(find.text('Navigate to Restaurant'));
    expect(advanced, 1);
  });

  testWidgets('restaurant phase shows pickup header', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(host(
        OrderModel.mock().copyWith(status: OrderStatus.accepted), () {}));
    expect(find.text('Pick up order'), findsOneWidget);
  });

  testWidgets('customer phase shows on-the-way header', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(host(
        OrderModel.mock().copyWith(status: OrderStatus.navigatingToCustomer),
        () {}));
    expect(find.text('Order picked up'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/dashboard/views/active_order_view_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement ActiveOrderView**

Create `frontend/lib/features/dashboard/views/active_order_view.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/order_model.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../widgets/customer_location_card.dart';
import '../widgets/earnings_strip.dart';
import '../widgets/order_details_card.dart';
import '../widgets/order_progress_tracker.dart';
import '../widgets/swipe_action_button.dart';

class ActiveOrderView extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onAdvance;

  const ActiveOrderView({
    super.key,
    required this.order,
    required this.onAdvance,
  });

  static bool _isRestaurantPhase(OrderStatus s) =>
      s == OrderStatus.accepted ||
      s == OrderStatus.navigatingToRestaurant ||
      s == OrderStatus.arrivedAtRestaurant;

  static String ctaLabelFor(OrderStatus s) {
    switch (s) {
      case OrderStatus.accepted:
        return 'Navigate to Restaurant';
      case OrderStatus.navigatingToRestaurant:
        return 'Reached Restaurant';
      case OrderStatus.arrivedAtRestaurant:
        return 'Confirm Pickup';
      case OrderStatus.pickupConfirmed:
      case OrderStatus.navigatingToCustomer:
        return 'Reached Customer';
      case OrderStatus.arrivedAtCustomer:
        return 'Confirm Delivery';
      default:
        return 'Continue';
    }
  }

  static bool isSwipeStatus(OrderStatus s) =>
      s == OrderStatus.arrivedAtRestaurant ||
      s == OrderStatus.arrivedAtCustomer;

  @override
  Widget build(BuildContext context) {
    final restaurant = _isRestaurantPhase(order.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          title: restaurant ? 'Pick up order' : 'Order picked up',
          subtitle: restaurant
              ? 'Go to the restaurant first'
              : 'Now deliver to the customer',
        ),
        const SizedBox(height: AppSpacing.md),
        OrderProgressTracker(status: order.status),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (restaurant)
                  _StatusBanner(
                    icon: LucideIcons.timer,
                    color: AppColors.secondary,
                    title: 'Pick up in ${order.etaMinutes} mins',
                    subtitle: 'Reach the restaurant asap to avoid delay',
                  )
                else
                  _StatusBanner(
                    icon: LucideIcons.checkCircle,
                    color: AppColors.success,
                    title: 'Order picked up at ${order.pickedUpAt ?? '10:25 AM'}',
                    subtitle: '${order.restaurantName}, ${order.restaurantArea}',
                  ),
                const SizedBox(height: AppSpacing.md),
                CustomerLocationCard(
                  title:
                      restaurant ? 'Restaurant Location' : 'Customer Location',
                  address:
                      restaurant ? order.restaurantArea : order.dropAddress,
                  pincode: restaurant ? null : order.dropPincode,
                  etaLine:
                      '${order.distanceKm} km away · ${order.etaMinutes} mins · Light traffic',
                ),
                const SizedBox(height: AppSpacing.md),
                OrderDetailsCard(order: order),
                const SizedBox(height: AppSpacing.md),
                EarningsStrip(amount: order.amount),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _BottomAction(status: order.status, onAdvance: onAdvance),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.h1.copyWith(fontSize: 24)),
              Text(subtitle,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.helpCircle, size: 18),
          label: const Text('Help'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.bodyMedium.copyWith(color: color)),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.phone, size: 16),
            label: const Text('Call'),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final OrderStatus status;
  final VoidCallback onAdvance;

  const _BottomAction({required this.status, required this.onAdvance});

  @override
  Widget build(BuildContext context) {
    final label = ActiveOrderView.ctaLabelFor(status);
    if (ActiveOrderView.isSwipeStatus(status)) {
      return SwipeActionButton(label: label, onConfirmed: onAdvance);
    }
    return Row(
      children: [
        _HelpIconButton(),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: PrimaryCtaButton(
            label: label,
            trailingIcon: LucideIcons.chevronsRight,
            onPressed: onAdvance,
          ),
        ),
      ],
    );
  }
}

class _HelpIconButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: () {},
        tooltip: 'Help & Support',
        icon: const Icon(LucideIcons.headphones, color: AppColors.primary),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/dashboard/views/active_order_view_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/dashboard/views/active_order_view.dart frontend/test/features/dashboard/views/active_order_view_test.dart
git commit -m "Add ActiveOrderView with phase-driven layout and swipe confirm"
```

---

### Task 11: Delivered widgets + OrderDeliveredView (state E)

**Files:**
- Create: `frontend/lib/features/dashboard/widgets/delivery_success_card.dart`
- Create: `frontend/lib/features/dashboard/widgets/rating_selector.dart`
- Create: `frontend/lib/features/dashboard/widgets/incentive_progress_card.dart`
- Create: `frontend/lib/features/dashboard/views/order_delivered_view.dart`
- Test: `frontend/test/features/dashboard/views/order_delivered_view_test.dart`

**Interfaces:**
- Consumes: `OrderModel`, `OrderProgressTracker`, `EarningsBreakdownWidget` (shared), `PrimaryCtaButton`, `CurrencyFormatter`.
- Produces:
  - `DeliverySuccessCard({required double amount, required String timestamp})`.
  - `RatingSelector()` — 5 labelled stars, local state; tapping fills stars and shows a thanks line.
  - `IncentiveProgressCard({required int completed, required int target, required double bonus})`.
  - `OrderDeliveredView({required OrderModel order, required VoidCallback onContinue})`.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/dashboard/views/order_delivered_view_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/views/order_delivered_view.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/rating_selector.dart';
import 'package:delivery_partner_app/models/orders/order_model.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('shows success amount and Continue', (tester) async {
    setTallSurface(tester);
    var continued = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OrderDeliveredView(
          order: OrderModel.mock(),
          onContinue: () => continued++,
        ),
      ),
    ));
    expect(find.text('Order delivered successfully!'), findsOneWidget);
    expect(find.text('₹38.50'), findsWidgets);
    await tester.tap(find.text('Continue'));
    expect(continued, 1);
  });

  testWidgets('RatingSelector selecting a star shows thanks', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: RatingSelector()),
    ));
    expect(find.text('Thanks for the feedback!'), findsNothing);
    await tester.tap(find.text('Good'));
    await tester.pump();
    expect(find.text('Thanks for the feedback!'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/dashboard/views/order_delivered_view_test.dart`
Expected: FAIL — files do not exist.

- [ ] **Step 3a: Implement DeliverySuccessCard**

Create `frontend/lib/features/dashboard/widgets/delivery_success_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class DeliverySuccessCard extends StatelessWidget {
  final double amount;
  final String timestamp;

  const DeliverySuccessCard({
    super.key,
    required this.amount,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.successBg, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(LucideIcons.check, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order delivered successfully!',
                    style: AppTypography.bodyMedium),
                Text(timestamp, style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xs),
                Text('You earned ${CurrencyFormatter.rupeesPrecise(amount)}',
                    style: AppTypography.numericMd
                        .copyWith(color: AppColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3b: Implement RatingSelector**

Create `frontend/lib/features/dashboard/widgets/rating_selector.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class RatingSelector extends StatefulWidget {
  const RatingSelector({super.key});

  @override
  State<RatingSelector> createState() => _RatingSelectorState();
}

class _RatingSelectorState extends State<RatingSelector> {
  static const _labels = ['Very Bad', 'Bad', 'Okay', 'Good', 'Excellent'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How was this delivery experience?',
              style: AppTypography.bodyMedium),
          Text('Your feedback helps us improve',
              style: AppTypography.caption),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final filled = i < _selected;
              return Semantics(
                label: 'Rate ${_labels[i]}, ${i + 1} of 5',
                button: true,
                child: GestureDetector(
                  onTap: () => setState(() => _selected = i + 1),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.star,
                        size: 28,
                        color: filled
                            ? AppColors.accent
                            : AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(_labels[i], style: AppTypography.caption),
                    ],
                  ),
                ),
              );
            }),
          ),
          if (_selected > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Thanks for the feedback!',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.success)),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 3c: Implement IncentiveProgressCard**

Create `frontend/lib/features/dashboard/widgets/incentive_progress_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class IncentiveProgressCard extends StatelessWidget {
  final int completed;
  final int target;
  final double bonus;

  const IncentiveProgressCard({
    super.key,
    required this.completed,
    required this.target,
    required this.bonus,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (target - completed).clamp(0, target);
    final progress = target == 0 ? 0.0 : (completed / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.target, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Incentive Challenge',
                    style: AppTypography.bodyMedium),
              ),
              Text('$completed / $target', style: AppTypography.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$remaining deliveries away from ${CurrencyFormatter.rupees(bonus)} extra',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surface,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3d: Implement OrderDeliveredView**

Create `frontend/lib/features/dashboard/views/order_delivered_view.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/order_model.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/misc/earnings_breakdown_widget.dart';
import '../widgets/delivery_success_card.dart';
import '../widgets/incentive_progress_card.dart';
import '../widgets/order_progress_tracker.dart';
import '../widgets/rating_selector.dart';

class OrderDeliveredView extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onContinue;

  const OrderDeliveredView({
    super.key,
    required this.order,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order delivered',
                      style: AppTypography.h1.copyWith(fontSize: 24)),
                  Text('Great job! 🎉',
                      style: AppTypography.body
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OrderProgressTracker(status: OrderStatus.deliveryConfirmed),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DeliverySuccessCard(
                    amount: order.amount, timestamp: '11:02 AM · 12 May 2025'),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    boxShadow: AppShadows.control,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.wallet,
                              size: 18, color: AppColors.success),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Earnings Breakdown',
                              style: AppTypography.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      EarningsBreakdownWidget(
                        base: order.deliveryFee,
                        distance: order.distancePay,
                        surge: order.incentive,
                        tip: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const RatingSelector(),
                const SizedBox(height: AppSpacing.md),
                const IncentiveProgressCard(
                    completed: 12, target: 20, bonus: 150),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryCtaButton(
          label: 'Continue',
          trailingIcon: LucideIcons.arrowRight,
          onPressed: onContinue,
        ),
      ],
    );
  }
}
```

Note: `EarningsBreakdownWidget` labels rows "Base fare / Distance / Surge / Tip". We map delivery fee → base, distance pay → distance, incentive → surge, 0 → tip; the total equals `order.amount` (38.50). The mockup's row labels differ but the shared widget is reused as-is per the reuse constraint; refining its labels is out of scope for this plan.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/dashboard/views/order_delivered_view_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/dashboard/widgets/delivery_success_card.dart frontend/lib/features/dashboard/widgets/rating_selector.dart frontend/lib/features/dashboard/widgets/incentive_progress_card.dart frontend/lib/features/dashboard/views/order_delivered_view.dart frontend/test/features/dashboard/views/order_delivered_view_test.dart
git commit -m "Add delivered-state widgets and OrderDeliveredView"
```

---

### Task 12: DashboardScreen shell rewrite + flow test

**Files:**
- Rewrite: `frontend/lib/features/dashboard/screens/dashboard_screen.dart`
- Test: `frontend/test/features/dashboard/screens/dashboard_screen_test.dart`

**Interfaces:**
- Consumes: `HomeIdleView`, `IncomingOrderScreen`, `ActiveOrderView`, `OrderDeliveredView`, `OrderModel`, `OrderStatus`, `FloatingBottomNav`, `ConfirmationDialog`, `ResponsiveFrame`.
- Produces: the shell mounted at `/dashboard`. Owns `online`, `status`, `currentOrder`, and the simulation `Timer`. Bottom nav visible only in idle/delivered states.

- [ ] **Step 1: Write the failing flow test**

Create `frontend/test/features/dashboard/screens/dashboard_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/dashboard/screens/dashboard_screen.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp() => GetMaterialApp(
      initialRoute: AppRoutes.dashboard,
      getPages: [
        GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),
      ],
    );

Future<void> goOnline(WidgetTester tester) async {
  await tester.tap(find.text('Go Online'));
  await tester.pumpAndSettle();
  // Confirmation dialog
  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts offline showing the offline hero', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text("You're offline"), findsOneWidget);
  });

  testWidgets('full happy path: offline → delivered → back to waiting',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await goOnline(tester);
    expect(find.text('Finding orders near you…'), findsOneWidget);

    // Simulated incoming order arrives after 2s.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('New Order'), findsOneWidget);

    await tester.tap(find.text('Accept Order'));
    await tester.pumpAndSettle();
    expect(find.text('Navigate to Restaurant'), findsOneWidget);

    await tester.tap(find.text('Navigate to Restaurant'));
    await tester.pumpAndSettle();
    expect(find.text('Reached Restaurant'), findsOneWidget);

    await tester.tap(find.text('Reached Restaurant'));
    await tester.pumpAndSettle();
    // arrivedAtRestaurant → swipe to Confirm Pickup
    await tester.drag(find.text('Confirm Pickup'), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Reached Customer'), findsOneWidget);

    await tester.tap(find.text('Reached Customer'));
    await tester.pumpAndSettle();
    // arrivedAtCustomer → swipe to Confirm Delivery
    await tester.drag(find.text('Confirm Delivery'), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Order delivered successfully!'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Finding orders near you…'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/dashboard/screens/dashboard_screen_test.dart`
Expected: FAIL — old `DashboardScreen` still references removed `OrderModel` fields / renders old UI; test cannot find new copy.

- [ ] **Step 3: Rewrite DashboardScreen**

Replace the entire `frontend/lib/features/dashboard/screens/dashboard_screen.dart` with:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/orders/order_model.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/floating_bottom_nav.dart';
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
    OrderStatus.pickupConfirmed: OrderStatus.navigatingToCustomer,
    OrderStatus.navigatingToCustomer: OrderStatus.arrivedAtCustomer,
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
              if (showNav)
                _BottomNav(activeIndex: _isDelivered ? 2 : 0),
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

class _BottomNav extends StatelessWidget {
  final int activeIndex;
  const _BottomNav({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return FloatingBottomNav(
      currentIndex: activeIndex,
      onTap: (_) {},
      items: const [
        NavItem(icon: LucideIcons.home, activeIcon: LucideIcons.home, label: 'Home'),
        NavItem(
            icon: LucideIcons.indianRupee,
            activeIcon: LucideIcons.indianRupee,
            label: 'Earnings'),
        NavItem(
            icon: LucideIcons.receipt,
            activeIcon: LucideIcons.receipt,
            label: 'Orders'),
        NavItem(icon: LucideIcons.user, activeIcon: LucideIcons.user, label: 'Profile'),
      ],
    );
  }
}
```

- [ ] **Step 4: Run the flow test to verify it passes**

Run: `cd frontend && flutter test test/features/dashboard/screens/dashboard_screen_test.dart`
Expected: PASS (2 tests). If the swipe drag distance is insufficient on the test surface, increase the `Offset(500, 0)` drag — the `SwipeActionButton` needs to cross 85% of its track width.

- [ ] **Step 5: Run the full dashboard test suite + analyzer**

Run: `cd frontend && flutter test test/features/dashboard/ && flutter analyze lib/features/dashboard lib/models/orders`
Expected: All tests PASS. Analyzer reports no errors (fix any unused-import warnings by removing the offending imports).

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/dashboard/screens/dashboard_screen.dart frontend/test/features/dashboard/screens/dashboard_screen_test.dart
git commit -m "Rewrite DashboardScreen as slim shell over decomposed views"
```

---

### Task 13: Full-suite verification & cleanup

**Files:**
- Verify only (no new production files).

- [ ] **Step 1: Run the entire test suite**

Run: `cd frontend && flutter test`
Expected: All tests PASS (existing registration/model tests + new dashboard tests). If any pre-existing test referenced the old `OrderModel` shape or old dashboard internals, update it minimally to the new API and note the change in the commit.

- [ ] **Step 2: Analyze the whole project**

Run: `cd frontend && flutter analyze`
Expected: No errors. Resolve warnings introduced by this work (unused imports, dead code from the deleted monolith).

- [ ] **Step 3: Confirm the monolith is gone**

Run: `wc -l frontend/lib/features/dashboard/screens/dashboard_screen.dart`
Expected: well under 200 lines (the shell), confirming the 57KB monolith no longer exists.

- [ ] **Step 4: Commit any cleanup**

```bash
git add -A
git commit -m "Verify full suite and clean up after dashboard refactor"
```

---

## Self-Review Notes

- **Spec coverage:** States A/B (Task 8), C (Task 9), D (Task 10), E (Task 11), shell/state-machine + bottom-nav visibility + go-offline-blocked (Task 12). Map placeholder (Task 2), progress tracker (Task 3), countdown ring with color thresholds + haptics (Task 4), swipe-to-confirm (Task 5), copy-to-clipboard + expandables + empty-note hiding (Task 7), rating selector + incentive + earnings breakdown reuse (Task 11), "Order missed" snackbar + auto-reject (Tasks 9, 12). Accessibility (Semantics/tooltip) present in Tasks 6, 10, 11.
- **Type consistency:** `OrderStatus`, `OrderModel.mock()`, `copyWith({status, pickedUpAt})`, `itemsSummary`, `itemCount`, `CurrencyFormatter.rupeesPrecise`, `AcceptCountdownRing.colorForRemaining`, `OrderProgressTracker.stageForStatus`, `ActiveOrderView.ctaLabelFor/isSwipeStatus`, `FloatingBottomNav(items/currentIndex/onTap)`, `StatusChip(label/color/background)`, `EarningsBreakdownWidget(base/distance/surge/tip)` all match their definitions across tasks.
- **Known deviation:** `EarningsBreakdownWidget` row labels ("Base fare/Distance/Surge/Tip") don't match the mockup's ("Delivery Fee/Distance Pay/Incentive"); reused as-is per the reuse constraint. Flagged in Task 11 as out of scope.
- **Haptics note:** Task 4's spec calls for haptics at 10s/5s thresholds; the ring implementation changes color at those thresholds. If explicit haptic pulses are desired, add `HapticFeedback.mediumImpact()` in the `remaining` transition inside `_AcceptCountdownRingState.build` guarded by a stored previous-value — deferred as a polish item to keep the tick logic test-stable.
