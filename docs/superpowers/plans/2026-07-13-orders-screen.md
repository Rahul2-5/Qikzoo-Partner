# Orders Screen ("My Orders") Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-level "My Orders" screen — date-grouped order list with four filtering tabs, functional search, and a sort/date filter sheet — at the existing `/orders` route.

**Architecture:** A `StatefulWidget` `OrdersScreen` holds the selected tab, search query, and sort/date filters, and derives the visible list through pure top-level functions (`filterEntries` → `sortEntries` → `groupByDate`) over a mock `OrderListEntry.mockList()`. Card taps are stubbed. `AppBottomNav(currentIndex: 2)` already routes here.

**Tech Stack:** Flutter, `get`, `lucide_icons`, `equatable`. No new packages.

## Global Constraints

- Package name for test imports: `delivery_partner_app`.
- Design tokens only: `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`.
- Money: `CurrencyFormatter.rupeesPrecise`.
- Reuse shared widgets: `ResponsiveFrame`, `SearchBarCustom`, `FilterChipCustom`, `StatusChip`,
  `EmptyState`, `AppBottomNav`.
- Screen wrapped in `SafeArea` + `ResponsiveFrame(maxWidth: 520)`.
- Status conveyed by icon + text + color, never color alone. Icon-only buttons get `tooltip`.
- No continuous animations needed; no controllers.
- Tests under `frontend/test/` mirroring `lib/`, `flutter_test`; widget-under-test wrapped in
  `MaterialApp`+`Scaffold`; screen/nav tests use `GetMaterialApp`. Use `setTallSurface`
  (physicalSize 400×N) to avoid overflow.

## File structure

```
frontend/lib/
  core/routes/app_pages.dart                    # MODIFY: register OrdersScreen
  models/orders/order_list_entry.dart           # CREATE: entry + enums + pure fns
  features/orders/
    screens/orders_screen.dart                  # CREATE
    widgets/
      orders_header.dart                        # CREATE
      orders_tab_bar.dart                        # CREATE
      date_group_header.dart                    # CREATE
      order_list_card.dart                      # CREATE
      orders_support_banner.dart                # CREATE
      order_filter_sheet.dart                   # CREATE
frontend/test/... mirrored ...
```

---

### Task 1: OrderListEntry model + enums + pure functions

**Files:**
- Create: `frontend/lib/models/orders/order_list_entry.dart`
- Test: `frontend/test/models/orders/order_list_entry_test.dart`

**Interfaces:**
- Produces:
  - `enum OrderListStatus { upcoming, completed, cancelled }`
  - `enum OrderBadge { newOrder, delivered, cancelled }` with `String get label`.
  - `enum OrdersTab { all, upcoming, completed, cancelled }` with `String get label` and
    `bool matches(OrderListEntry e)`.
  - `enum OrdersSort { newest, highestEarning }` with `String get label`.
  - `enum OrdersDateFilter { all, today }` with `String get label`.
  - `class OrderListEntry` (Equatable) with the fields listed below and
    `static List<OrderListEntry> mockList()`.
  - `List<OrderListEntry> filterEntries({required List<OrderListEntry> all, required OrdersTab tab,
    required String query, required OrdersDateFilter dateFilter})`
  - `List<OrderListEntry> sortEntries(List<OrderListEntry> entries, OrdersSort sort)`
  - `Map<String, List<OrderListEntry>> groupByDate(List<OrderListEntry> entries)`

- [ ] **Step 1: Write the failing test**

Create `frontend/test/models/orders/order_list_entry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/orders/order_list_entry.dart';

void main() {
  final all = OrderListEntry.mockList();

  test('mockList covers every status', () {
    expect(all.any((e) => e.status == OrderListStatus.upcoming), isTrue);
    expect(all.any((e) => e.status == OrderListStatus.completed), isTrue);
    expect(all.any((e) => e.status == OrderListStatus.cancelled), isTrue);
  });

  test('OrdersTab.matches filters by status', () {
    final e = all.firstWhere((x) => x.status == OrderListStatus.cancelled);
    expect(OrdersTab.all.matches(e), isTrue);
    expect(OrdersTab.cancelled.matches(e), isTrue);
    expect(OrdersTab.completed.matches(e), isFalse);
  });

  test('filterEntries narrows by tab', () {
    final completed = filterEntries(
        all: all,
        tab: OrdersTab.completed,
        query: '',
        dateFilter: OrdersDateFilter.all);
    expect(completed, isNotEmpty);
    expect(completed.every((e) => e.status == OrderListStatus.completed), isTrue);
  });

  test('filterEntries matches restaurant and id case-insensitively', () {
    final byName = filterEntries(
        all: all,
        tab: OrdersTab.all,
        query: 'burger',
        dateFilter: OrdersDateFilter.all);
    expect(byName.length, 1);
    expect(byName.single.restaurantName, 'Burger Point');

    final byId = filterEntries(
        all: all,
        tab: OrdersTab.all,
        query: '171287364912',
        dateFilter: OrdersDateFilter.all);
    expect(byId.length, 1);
  });

  test('filterEntries today keeps only today entries', () {
    final today = filterEntries(
        all: all,
        tab: OrdersTab.all,
        query: '',
        dateFilter: OrdersDateFilter.today);
    expect(today.every((e) => e.dateGroup.startsWith('Today')), isTrue);
    expect(today.length, lessThan(all.length));
  });

  test('sortEntries highestEarning orders by amount desc', () {
    final sorted = sortEntries(all, OrdersSort.highestEarning);
    for (var i = 1; i < sorted.length; i++) {
      expect(sorted[i - 1].amount, greaterThanOrEqualTo(sorted[i].amount));
    }
  });

  test('groupByDate preserves first-seen group order', () {
    final groups = groupByDate(all);
    expect(groups.keys.first, startsWith('Today'));
    expect(groups.keys.length, greaterThanOrEqualTo(2));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/models/orders/order_list_entry_test.dart`
Expected: FAIL — file/types not defined.

- [ ] **Step 3: Create the model**

Create `frontend/lib/models/orders/order_list_entry.dart`:

```dart
import 'dart:collection';
import 'package:equatable/equatable.dart';

enum OrderListStatus { upcoming, completed, cancelled }

enum OrderBadge {
  newOrder,
  delivered,
  cancelled;

  String get label => switch (this) {
        OrderBadge.newOrder => 'New',
        OrderBadge.delivered => 'Delivered',
        OrderBadge.cancelled => 'Cancelled',
      };
}

enum OrdersTab {
  all,
  upcoming,
  completed,
  cancelled;

  String get label => switch (this) {
        OrdersTab.all => 'All Orders',
        OrdersTab.upcoming => 'Upcoming',
        OrdersTab.completed => 'Completed',
        OrdersTab.cancelled => 'Cancelled',
      };

  bool matches(OrderListEntry e) => switch (this) {
        OrdersTab.all => true,
        OrdersTab.upcoming => e.status == OrderListStatus.upcoming,
        OrdersTab.completed => e.status == OrderListStatus.completed,
        OrdersTab.cancelled => e.status == OrderListStatus.cancelled,
      };
}

enum OrdersSort {
  newest,
  highestEarning;

  String get label => switch (this) {
        OrdersSort.newest => 'Newest',
        OrdersSort.highestEarning => 'Highest earning',
      };
}

enum OrdersDateFilter {
  all,
  today;

  String get label => switch (this) {
        OrdersDateFilter.all => 'All time',
        OrdersDateFilter.today => 'Today',
      };
}

class OrderListEntry extends Equatable {
  final String id;
  final String restaurantName;
  final String restaurantArea;
  final String dropAddress;
  final double distanceKm;
  final String timeAwayLabel;
  final double amount;
  final String timeLabel;
  final String dateGroup;
  final OrderListStatus status;
  final OrderBadge badge;

  const OrderListEntry({
    required this.id,
    required this.restaurantName,
    required this.restaurantArea,
    required this.dropAddress,
    required this.distanceKm,
    required this.timeAwayLabel,
    required this.amount,
    required this.timeLabel,
    required this.dateGroup,
    required this.status,
    required this.badge,
  });

  static List<OrderListEntry> mockList() => const [
        OrderListEntry(
          id: '#171287364912',
          restaurantName: 'The Biryani House',
          restaurantArea: 'Goregaon West, Mumbai',
          dropAddress: 'Sundervan Complex, Andheri West, Mumbai',
          distanceKm: 4.2,
          timeAwayLabel: '12 mins away',
          amount: 38.50,
          timeLabel: '11:30 AM',
          dateGroup: 'Today, 12 May 2025',
          status: OrderListStatus.upcoming,
          badge: OrderBadge.newOrder,
        ),
        OrderListEntry(
          id: '#171287124578',
          restaurantName: 'The Biryani House',
          restaurantArea: 'Goregaon West, Mumbai',
          dropAddress: 'Lokhandwala Complex, Andheri West, Mumbai',
          distanceKm: 4.6,
          timeAwayLabel: '15 mins',
          amount: 46.00,
          timeLabel: '10:25 AM',
          dateGroup: 'Today, 12 May 2025',
          status: OrderListStatus.completed,
          badge: OrderBadge.delivered,
        ),
        OrderListEntry(
          id: '#171286889341',
          restaurantName: 'Burger Point',
          restaurantArea: 'Versova, Andheri West',
          dropAddress: 'Yari Road, Versova, Andheri West, Mumbai',
          distanceKm: 2.1,
          timeAwayLabel: '8 mins',
          amount: 32.50,
          timeLabel: '09:15 AM',
          dateGroup: 'Today, 12 May 2025',
          status: OrderListStatus.completed,
          badge: OrderBadge.delivered,
        ),
        OrderListEntry(
          id: '#171276554801',
          restaurantName: 'Pizza Corner',
          restaurantArea: 'Juhu Tara Road, Mumbai',
          dropAddress: 'JVPD Scheme, Juhu, Mumbai',
          distanceKm: 5.2,
          timeAwayLabel: '18 mins',
          amount: 55.00,
          timeLabel: '08:20 PM',
          dateGroup: 'Yesterday, 11 May 2025',
          status: OrderListStatus.completed,
          badge: OrderBadge.delivered,
        ),
        OrderListEntry(
          id: '#171276112233',
          restaurantName: 'Cake Studio',
          restaurantArea: 'Bandra West, Mumbai',
          dropAddress: 'Hill Road, Bandra West, Mumbai',
          distanceKm: 3.0,
          timeAwayLabel: '11 mins',
          amount: 0.00,
          timeLabel: '06:40 PM',
          dateGroup: 'Yesterday, 11 May 2025',
          status: OrderListStatus.cancelled,
          badge: OrderBadge.cancelled,
        ),
      ];

  @override
  List<Object?> get props => [
        id,
        restaurantName,
        restaurantArea,
        dropAddress,
        distanceKm,
        timeAwayLabel,
        amount,
        timeLabel,
        dateGroup,
        status,
        badge,
      ];
}

List<OrderListEntry> filterEntries({
  required List<OrderListEntry> all,
  required OrdersTab tab,
  required String query,
  required OrdersDateFilter dateFilter,
}) {
  final q = query.trim().toLowerCase();
  return all.where((e) {
    if (!tab.matches(e)) return false;
    if (dateFilter == OrdersDateFilter.today &&
        !e.dateGroup.startsWith('Today')) {
      return false;
    }
    if (q.isEmpty) return true;
    return e.restaurantName.toLowerCase().contains(q) ||
        e.id.toLowerCase().contains(q);
  }).toList();
}

List<OrderListEntry> sortEntries(
    List<OrderListEntry> entries, OrdersSort sort) {
  if (sort == OrdersSort.newest) return entries;
  final copy = [...entries];
  copy.sort((a, b) => b.amount.compareTo(a.amount));
  return copy;
}

Map<String, List<OrderListEntry>> groupByDate(List<OrderListEntry> entries) {
  final map = LinkedHashMap<String, List<OrderListEntry>>();
  for (final e in entries) {
    map.putIfAbsent(e.dateGroup, () => []).add(e);
  }
  return map;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd frontend && flutter test test/models/orders/order_list_entry_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/models/orders/order_list_entry.dart frontend/test/models/orders/order_list_entry_test.dart
git commit -m "Add OrderListEntry model, tabs/sort/filter enums, and pure list functions"
```

---

### Task 2: OrdersTabBar + DateGroupHeader + OrdersSupportBanner

**Files:**
- Create: `frontend/lib/features/orders/widgets/orders_tab_bar.dart`
- Create: `frontend/lib/features/orders/widgets/date_group_header.dart`
- Create: `frontend/lib/features/orders/widgets/orders_support_banner.dart`
- Test: `frontend/test/features/orders/widgets/orders_small_widgets_test.dart`

**Interfaces:**
- Consumes: `OrdersTab` (Task 1).
- Produces:
  - `OrdersTabBar({required OrdersTab current, required ValueChanged<OrdersTab> onChanged})`.
  - `DateGroupHeader({required String label})`.
  - `OrdersSupportBanner({VoidCallback? onGetSupport})`.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/orders/widgets/orders_small_widgets_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/orders/widgets/orders_tab_bar.dart';
import 'package:delivery_partner_app/features/orders/widgets/date_group_header.dart';
import 'package:delivery_partner_app/features/orders/widgets/orders_support_banner.dart';
import 'package:delivery_partner_app/models/orders/order_list_entry.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('OrdersTabBar renders four labels and reports taps',
      (tester) async {
    OrdersTab? picked;
    await tester.pumpWidget(wrap(OrdersTabBar(
      current: OrdersTab.all,
      onChanged: (t) => picked = t,
    )));
    expect(find.text('All Orders'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    await tester.tap(find.text('Cancelled'));
    expect(picked, OrdersTab.cancelled);
  });

  testWidgets('DateGroupHeader shows the label', (tester) async {
    await tester.pumpWidget(wrap(const DateGroupHeader(label: 'Today, 12 May 2025')));
    expect(find.text('Today, 12 May 2025'), findsOneWidget);
  });

  testWidgets('OrdersSupportBanner fires Get Support', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(wrap(OrdersSupportBanner(onGetSupport: () => tapped++)));
    await tester.tap(find.text('Get Support'));
    expect(tapped, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/orders/widgets/orders_small_widgets_test.dart`
Expected: FAIL — files not defined.

- [ ] **Step 3: Create OrdersTabBar**

Create `frontend/lib/features/orders/widgets/orders_tab_bar.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/order_list_entry.dart';

class OrdersTabBar extends StatelessWidget {
  final OrdersTab current;
  final ValueChanged<OrdersTab> onChanged;

  const OrdersTabBar({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          for (final tab in OrdersTab.values)
            _Tab(
              label: tab.label,
              selected: tab == current,
              onTap: () => onChanged(tab),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              height: 3,
              width: 24,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create DateGroupHeader**

Create `frontend/lib/features/orders/widgets/date_group_header.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class DateGroupHeader extends StatelessWidget {
  final String label;

  const DateGroupHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(LucideIcons.calendar,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(label,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Create OrdersSupportBanner**

Create `frontend/lib/features/orders/widgets/orders_support_banner.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class OrdersSupportBanner extends StatelessWidget {
  final VoidCallback? onGetSupport;

  const OrdersSupportBanner({super.key, this.onGetSupport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: const Icon(LucideIcons.headphones, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Facing an issue with your order?',
                    style: AppTypography.bodyMedium),
                Text('Get help from our support team.',
                    style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton(
            onPressed: onGetSupport,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control)),
            ),
            child: const Text('Get Support'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd frontend && flutter test test/features/orders/widgets/orders_small_widgets_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/orders/widgets/orders_tab_bar.dart frontend/lib/features/orders/widgets/date_group_header.dart frontend/lib/features/orders/widgets/orders_support_banner.dart frontend/test/features/orders/widgets/orders_small_widgets_test.dart
git commit -m "Add OrdersTabBar, DateGroupHeader, and OrdersSupportBanner"
```

---

### Task 3: OrderListCard

**Files:**
- Create: `frontend/lib/features/orders/widgets/order_list_card.dart`
- Test: `frontend/test/features/orders/widgets/order_list_card_test.dart`

**Interfaces:**
- Consumes: `OrderListEntry`, `OrderListStatus`, `OrderBadge` (Task 1), `StatusChip`,
  `CurrencyFormatter`.
- Produces: `OrderListCard({required OrderListEntry entry, required VoidCallback onTap})`.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/orders/widgets/order_list_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/orders/widgets/order_list_card.dart';
import 'package:delivery_partner_app/models/orders/order_list_entry.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  final upcoming =
      OrderListEntry.mockList().firstWhere((e) => e.status == OrderListStatus.upcoming);
  final completed =
      OrderListEntry.mockList().firstWhere((e) => e.status == OrderListStatus.completed);

  testWidgets('renders id, restaurant, badge and amount', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(wrap(OrderListCard(entry: upcoming, onTap: () {})));
    expect(find.text(upcoming.id), findsOneWidget);
    expect(find.text('The Biryani House'), findsWidgets);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('₹38.50'), findsOneWidget);
  });

  testWidgets('upcoming shows View Details, completed does not', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(wrap(OrderListCard(entry: upcoming, onTap: () {})));
    expect(find.text('View Details'), findsOneWidget);

    await tester.pumpWidget(wrap(OrderListCard(entry: completed, onTap: () {})));
    expect(find.text('View Details'), findsNothing);
  });

  testWidgets('tapping the card fires onTap', (tester) async {
    setTallSurface(tester);
    var taps = 0;
    await tester.pumpWidget(wrap(OrderListCard(entry: completed, onTap: () => taps++)));
    await tester.tap(find.text(completed.id));
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/orders/widgets/order_list_card_test.dart`
Expected: FAIL — file not defined.

- [ ] **Step 3: Implement OrderListCard**

Create `frontend/lib/features/orders/widgets/order_list_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/order_list_entry.dart';
import '../../../shared/widgets/chips/status_chip.dart';

class OrderListCard extends StatelessWidget {
  final OrderListEntry entry;
  final VoidCallback onTap;

  const OrderListCard({super.key, required this.entry, required this.onTap});

  ({Color color, Color bg, IconData icon, String word}) get _statusStyle =>
      switch (entry.status) {
        OrderListStatus.upcoming => (
            color: AppColors.success,
            bg: AppColors.successBg,
            icon: LucideIcons.history,
            word: 'Upcoming'
          ),
        OrderListStatus.completed => (
            color: AppColors.primary,
            bg: AppColors.primarySoft,
            icon: LucideIcons.check,
            word: 'Completed'
          ),
        OrderListStatus.cancelled => (
            color: AppColors.error,
            bg: AppColors.error.withValues(alpha: 0.12),
            icon: LucideIcons.x,
            word: 'Cancelled'
          ),
      };

  ({Color color, Color bg}) get _badgeStyle => switch (entry.badge) {
        OrderBadge.newOrder => (color: AppColors.warning, bg: AppColors.warningBg),
        OrderBadge.delivered => (color: AppColors.success, bg: AppColors.successBg),
        OrderBadge.cancelled => (
            color: AppColors.error,
            bg: AppColors.error.withValues(alpha: 0.12)
          ),
      };

  @override
  Widget build(BuildContext context) {
    final s = _statusStyle;
    final b = _badgeStyle;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.control),
              boxShadow: AppShadows.control,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Rail(style: s, timeLabel: entry.timeLabel),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Order ID', style: AppTypography.caption),
                                    Text(entry.id,
                                        style: AppTypography.bodyMedium),
                                  ],
                                ),
                              ),
                              StatusChip(
                                  label: entry.badge.label,
                                  color: b.color,
                                  background: b.bg),
                              const SizedBox(width: AppSpacing.sm),
                              Text(CurrencyFormatter.rupeesPrecise(entry.amount),
                                  style: AppTypography.bodyMedium),
                              const Icon(LucideIcons.chevronRight,
                                  size: 16, color: AppColors.textSecondary),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                    color: AppColors.warning,
                                    shape: BoxShape.circle),
                                child: const Icon(LucideIcons.store,
                                    color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.restaurantName,
                                        style: AppTypography.bodyMedium),
                                    Text(entry.restaurantArea,
                                        style: AppTypography.caption),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.mapPin,
                                  size: 18, color: AppColors.success),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(entry.dropAddress,
                                    style: AppTypography.caption),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${entry.distanceKm} km  •  ${entry.timeAwayLabel}',
                            style: AppTypography.caption,
                          ),
                          if (entry.status == OrderListStatus.upcoming) ...[
                            const SizedBox(height: AppSpacing.md),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton(
                                onPressed: onTap,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.control)),
                                ),
                                child: const Text('View Details'),
                              ),
                            ),
                          ],
                        ],
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
}

class _Rail extends StatelessWidget {
  final ({Color color, Color bg, IconData icon, String word}) style;
  final String timeLabel;

  const _Rail({required this.style, required this.timeLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.control),
          bottomLeft: Radius.circular(AppRadius.control),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(style.word,
              textAlign: TextAlign.center,
              style: AppTypography.caption
                  .copyWith(color: style.color, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(timeLabel,
              textAlign: TextAlign.center,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Icon(style.icon, size: 18, color: style.color),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/orders/widgets/order_list_card_test.dart`
Expected: PASS (3 tests). Both "The Biryani House" strings (rail area none; restaurant row +
possibly nothing else) — the test uses `findsWidgets` for the restaurant name to tolerate it.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/orders/widgets/order_list_card.dart frontend/test/features/orders/widgets/order_list_card_test.dart
git commit -m "Add OrderListCard with status rail and badges"
```

---

### Task 4: OrderFilterSheet

**Files:**
- Create: `frontend/lib/features/orders/widgets/order_filter_sheet.dart`
- Test: `frontend/test/features/orders/widgets/order_filter_sheet_test.dart`

**Interfaces:**
- Consumes: `OrdersSort`, `OrdersDateFilter` (Task 1), `FilterChipCustom`, `PrimaryCtaButton`.
- Produces:
  - `class OrdersFilterResult { final OrdersSort sort; final OrdersDateFilter dateFilter;
    const OrdersFilterResult({required this.sort, required this.dateFilter}); }`
  - `class OrderFilterSheet` with
    `static Future<OrdersFilterResult?> show(BuildContext context, {required OrdersSort sort,
    required OrdersDateFilter dateFilter})`.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/orders/widgets/order_filter_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/orders/widgets/order_filter_sheet.dart';
import 'package:delivery_partner_app/models/orders/order_list_entry.dart';

void main() {
  testWidgets('selecting Highest earning and Apply returns it', (tester) async {
    OrdersFilterResult? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await OrderFilterSheet.show(
                  context,
                  sort: OrdersSort.newest,
                  dateFilter: OrdersDateFilter.all,
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

    await tester.tap(find.text('Highest earning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.sort, OrdersSort.highestEarning);
    expect(result!.dateFilter, OrdersDateFilter.all);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/orders/widgets/order_filter_sheet_test.dart`
Expected: FAIL — file not defined.

- [ ] **Step 3: Implement OrderFilterSheet**

Create `frontend/lib/features/orders/widgets/order_filter_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/order_list_entry.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/chips/filter_chip_custom.dart';

class OrdersFilterResult {
  final OrdersSort sort;
  final OrdersDateFilter dateFilter;

  const OrdersFilterResult({required this.sort, required this.dateFilter});
}

class OrderFilterSheet extends StatefulWidget {
  final OrdersSort sort;
  final OrdersDateFilter dateFilter;

  const OrderFilterSheet({
    super.key,
    required this.sort,
    required this.dateFilter,
  });

  static Future<OrdersFilterResult?> show(
    BuildContext context, {
    required OrdersSort sort,
    required OrdersDateFilter dateFilter,
  }) {
    return showModalBottomSheet<OrdersFilterResult>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (_) => OrderFilterSheet(sort: sort, dateFilter: dateFilter),
    );
  }

  @override
  State<OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<OrderFilterSheet> {
  late OrdersSort _sort = widget.sort;
  late OrdersDateFilter _dateFilter = widget.dateFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sort & Filter', style: AppTypography.h2),
              TextButton(
                onPressed: () => setState(() {
                  _sort = OrdersSort.newest;
                  _dateFilter = OrdersDateFilter.all;
                }),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Sort by', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final s in OrdersSort.values)
                FilterChipCustom(
                  label: s.label,
                  selected: s == _sort,
                  onTap: () => setState(() => _sort = s),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Date', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final d in OrdersDateFilter.values)
                FilterChipCustom(
                  label: d.label,
                  selected: d == _dateFilter,
                  onTap: () => setState(() => _dateFilter = d),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryCtaButton(
            label: 'Apply',
            onPressed: () => Navigator.of(context).pop(
              OrdersFilterResult(sort: _sort, dateFilter: _dateFilter),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/orders/widgets/order_filter_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/orders/widgets/order_filter_sheet.dart frontend/test/features/orders/widgets/order_filter_sheet_test.dart
git commit -m "Add OrderFilterSheet with sort and date filters"
```

---

### Task 5: OrdersHeader

**Files:**
- Create: `frontend/lib/features/orders/widgets/orders_header.dart`
- Test: `frontend/test/features/orders/widgets/orders_header_test.dart`

**Interfaces:**
- Consumes: `SearchBarCustom`.
- Produces: `OrdersHeader({required bool searchOpen, required String query,
  required VoidCallback onToggleSearch, required ValueChanged<String> onQueryChanged,
  required VoidCallback onOpenFilter})`.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/orders/widgets/orders_header_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/orders/widgets/orders_header.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows the My Orders title and toggles search', (tester) async {
    var toggled = 0;
    await tester.pumpWidget(wrap(OrdersHeader(
      searchOpen: false,
      query: '',
      onToggleSearch: () => toggled++,
      onQueryChanged: (_) {},
      onOpenFilter: () {},
    )));
    expect(find.text('My Orders'), findsOneWidget);
    await tester.tap(find.byTooltip('Search'));
    expect(toggled, 1);
  });

  testWidgets('shows the search field when open', (tester) async {
    await tester.pumpWidget(wrap(OrdersHeader(
      searchOpen: true,
      query: '',
      onToggleSearch: () {},
      onQueryChanged: (_) {},
      onOpenFilter: () {},
    )));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('filter button fires onOpenFilter', (tester) async {
    var opened = 0;
    await tester.pumpWidget(wrap(OrdersHeader(
      searchOpen: false,
      query: '',
      onToggleSearch: () {},
      onQueryChanged: (_) {},
      onOpenFilter: () => opened++,
    )));
    await tester.tap(find.byTooltip('Filter'));
    expect(opened, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/orders/widgets/orders_header_test.dart`
Expected: FAIL — file not defined.

- [ ] **Step 3: Implement OrdersHeader**

Create `frontend/lib/features/orders/widgets/orders_header.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/inputs/search_bar_custom.dart';

class OrdersHeader extends StatefulWidget {
  final bool searchOpen;
  final String query;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onOpenFilter;

  const OrdersHeader({
    super.key,
    required this.searchOpen,
    required this.query,
    required this.onToggleSearch,
    required this.onQueryChanged,
    required this.onOpenFilter,
  });

  @override
  State<OrdersHeader> createState() => _OrdersHeaderState();
}

class _OrdersHeaderState extends State<OrdersHeader> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QIKZOO',
                    style: AppTypography.h2.copyWith(color: AppColors.primary)),
                Text('Delivery Partner', style: AppTypography.caption),
              ],
            ),
            const Spacer(),
            const _OnlinePill(),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text('My Orders', style: AppTypography.h1),
            const Spacer(),
            _IconAction(
              icon: LucideIcons.search,
              tooltip: 'Search',
              onTap: widget.onToggleSearch,
            ),
            const SizedBox(width: AppSpacing.sm),
            _IconAction(
              icon: LucideIcons.slidersHorizontal,
              tooltip: 'Filter',
              onTap: widget.onOpenFilter,
            ),
          ],
        ),
        if (widget.searchOpen) ...[
          const SizedBox(height: AppSpacing.md),
          SearchBarCustom(
            controller: _controller,
            hint: 'Search by restaurant or order ID',
            onChanged: widget.onQueryChanged,
          ),
        ],
      ],
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill();

  @override
  Widget build(BuildContext context) {
    return Container(
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
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Online', style: AppTypography.bodyMedium),
          const Icon(LucideIcons.chevronDown,
              size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/orders/widgets/orders_header_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/orders/widgets/orders_header.dart frontend/test/features/orders/widgets/orders_header_test.dart
git commit -m "Add OrdersHeader with online pill and search/filter actions"
```

---

### Task 6: OrdersScreen assembly + route registration

**Files:**
- Create: `frontend/lib/features/orders/screens/orders_screen.dart`
- Modify: `frontend/lib/core/routes/app_pages.dart`
- Test: `frontend/test/features/orders/screens/orders_screen_test.dart`

**Interfaces:**
- Consumes: all orders widgets (Tasks 2–5), model + pure fns (Task 1), `AppBottomNav`,
  `ResponsiveFrame`, `EmptyState`, `AppRoutes`.
- Produces: `OrdersScreen` at `AppRoutes.orders`.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/orders/screens/orders_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/orders/screens/orders_screen.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp() => GetMaterialApp(
      initialRoute: AppRoutes.orders,
      getPages: [
        GetPage(name: AppRoutes.orders, page: () => const OrdersScreen()),
        GetPage(
            name: AppRoutes.dashboard,
            page: () => const Scaffold(body: Text('Dashboard Screen'))),
        GetPage(
            name: AppRoutes.earnings,
            page: () => const Scaffold(body: Text('Earnings Screen'))),
        GetPage(
            name: AppRoutes.profile,
            page: () => const Scaffold(body: Text('Profile Screen'))),
      ],
    );

void main() {
  testWidgets('defaults to All and shows both date groups', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('Today, 12 May 2025'), findsOneWidget);
    expect(find.text('Yesterday, 11 May 2025'), findsOneWidget);
  });

  testWidgets('Cancelled tab shows only the cancelled entry', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelled'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsWidgets); // tab + badge/rail
    expect(find.text('Cake Studio'), findsOneWidget);
    expect(find.text('Burger Point'), findsNothing);
  });

  testWidgets('search narrows to Burger Point', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'burger');
    await tester.pumpAndSettle();
    expect(find.text('Burger Point'), findsOneWidget);
    expect(find.text('Pizza Corner'), findsNothing);
  });

  testWidgets('empty query result shows the empty state', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pumpAndSettle();
    expect(find.text('No orders here yet'), findsOneWidget);
  });

  testWidgets('Home tab navigates to the dashboard', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Screen'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/orders/screens/orders_screen_test.dart`
Expected: FAIL — `OrdersScreen` not defined.

- [ ] **Step 3: Create OrdersScreen**

Create `frontend/lib/features/orders/screens/orders_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/orders/order_list_entry.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/navigation/app_bottom_nav.dart';
import '../widgets/date_group_header.dart';
import '../widgets/order_filter_sheet.dart';
import '../widgets/order_list_card.dart';
import '../widgets/orders_header.dart';
import '../widgets/orders_support_banner.dart';
import '../widgets/orders_tab_bar.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _all = OrderListEntry.mockList();
  OrdersTab _tab = OrdersTab.all;
  String _query = '';
  bool _searchOpen = false;
  OrdersSort _sort = OrdersSort.newest;
  OrdersDateFilter _dateFilter = OrdersDateFilter.all;

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) _query = '';
    });
  }

  Future<void> _openFilter() async {
    final result = await OrderFilterSheet.show(
      context,
      sort: _sort,
      dateFilter: _dateFilter,
    );
    if (result != null) {
      setState(() {
        _sort = result.sort;
        _dateFilter = result.dateFilter;
      });
    }
  }

  void _openDetails(OrderListEntry entry) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order details coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filterEntries(
      all: _all,
      tab: _tab,
      query: _query,
      dateFilter: _dateFilter,
    );
    final sorted = sortEntries(filtered, _sort);
    final groups = groupByDate(sorted);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OrdersHeader(
                searchOpen: _searchOpen,
                query: _query,
                onToggleSearch: _toggleSearch,
                onQueryChanged: (q) => setState(() => _query = q),
                onOpenFilter: _openFilter,
              ),
              const SizedBox(height: AppSpacing.md),
              OrdersTabBar(
                current: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: sorted.isEmpty
                    ? const EmptyState(
                        icon: LucideIcons.inbox,
                        message: 'No orders here yet',
                      )
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          for (final entry in groups.entries) ...[
                            DateGroupHeader(label: entry.key),
                            for (final order in entry.value)
                              OrderListCard(
                                entry: order,
                                onTap: () => _openDetails(order),
                              ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          OrdersSupportBanner(onGetSupport: () {}),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
              ),
              const AppBottomNav(currentIndex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Register the route**

In `frontend/lib/core/routes/app_pages.dart`:

1. Add import:

```dart
import '../../features/orders/screens/orders_screen.dart';
```

2. Replace the existing orders placeholder registration:

```dart
    GetPage(
        name: AppRoutes.orders,
        page: () => const PlaceholderScreen(title: 'Orders')),
```

with:

```dart
    GetPage(name: AppRoutes.orders, page: () => const OrdersScreen()),
```

- [ ] **Step 5: Run the screen tests to verify they pass**

Run: `cd frontend && flutter test test/features/orders/screens/orders_screen_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 6: Analyze the touched libraries**

Run: `cd frontend && flutter analyze lib/features/orders lib/models/orders lib/core/routes`
Expected: No issues.

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/orders/screens/orders_screen.dart frontend/lib/core/routes/app_pages.dart frontend/test/features/orders/screens/orders_screen_test.dart
git commit -m "Add OrdersScreen and register the /orders route"
```

---

### Task 7: Full-suite verification

**Files:** Verify only.

- [ ] **Step 1: Run the entire test suite**

Run: `cd frontend && flutter test`
Expected: All tests PASS (existing Home/Earnings/registration tests plus the new orders tests).

- [ ] **Step 2: Analyze the whole project**

Run: `cd frontend && flutter analyze`
Expected: No new errors/warnings from this work (a pre-existing info-level lint in
`document_upload_actions.dart` is unrelated and may remain).

- [ ] **Step 3: Commit any cleanup**

```bash
git add -A
git commit -m "Verify full suite after Orders screen"
```

---

## Self-Review Notes

- **Spec coverage:** model + enums + pure fns (Task 1); tab bar + date header + support banner
  (Task 2); rich order card with status rail + badges + View Details (Task 3); sort/date filter
  sheet (Task 4); header with online pill + search toggle + filter action (Task 5); screen
  assembly (filter→sort→group pipeline, empty state, snackbar stub) + route registration + nav
  (Task 6); verification (Task 7). Functional tabs/search/filter and nav all covered by the
  OrdersScreen tests.
- **Placeholder scan:** none — every step has full code.
- **Type consistency:** `OrdersTab.matches/label`, `OrderBadge.label`, `OrdersSort.label`,
  `OrdersDateFilter.label`, `filterEntries(all/tab/query/dateFilter)`, `sortEntries(entries,sort)`,
  `groupByDate`, `OrderListCard(entry,onTap)`, `OrdersTabBar(current,onChanged)`,
  `OrdersHeader(searchOpen,query,onToggleSearch,onQueryChanged,onOpenFilter)`,
  `OrderFilterSheet.show(context, sort:, dateFilter:) → OrdersFilterResult`,
  `AppBottomNav(currentIndex)`, `StatusChip(label,color,background)`,
  `SearchBarCustom(controller,hint,onChanged)`, `FilterChipCustom(label,selected,onTap)`,
  `EmptyState(icon,message)` all match their definitions.
- **Known deviation:** when sorting by Highest earning, date-group headers follow first-seen
  order of the sorted list rather than chronology — acceptable for a mock sort; grouping still
  renders correctly.
