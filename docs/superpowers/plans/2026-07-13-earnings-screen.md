# Earnings Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-level Earnings screen (total, category breakdown, custom bar chart, history, next payout) driven by a functional period toggle, and wire the shared bottom nav so Home↔Earnings tab-switching works.

**Architecture:** A `StatefulWidget` `EarningsScreen` at a new `/earnings` route holds the selected `EarningsPeriod` and rebuilds from `EarningsSummary.forPeriod(period)` (pure mock, no Riverpod). The dashboard's private bottom nav is extracted into a shared `AppBottomNav` that routes between tabs with `Get.offNamed`. The bar chart is hand-built (no chart package).

**Tech Stack:** Flutter, `get`, `lucide_icons`, `equatable`. No new packages.

## Global Constraints

- Package name for test imports: `delivery_partner_app`.
- Design tokens only: `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`.
  No raw hex/size literals except inside `CustomPainter` geometry.
- Money with paise: `CurrencyFormatter.rupeesPrecise` (₹2,345.50). Whole-rupee axis ticks:
  `CurrencyFormatter.rupees` (₹200).
- Reuse shared widgets: `ResponsiveFrame`, `FloatingBottomNav` (+ `NavItem`), `StatusChip`,
  `PrimaryCtaButton`.
- Screen wrapped in `SafeArea` + `ResponsiveFrame(maxWidth: 520)`.
- Delta shown as icon + colored text, never color alone.
- Animations use `TweenAnimationBuilder` only (no controllers to dispose).
- Tests under `frontend/test/` mirroring `lib/`, `flutter_test`; widget-under-test wrapped in
  `MaterialApp`+`Scaffold`; screen/nav tests use `GetMaterialApp`. Use the `setTallSurface`
  helper (physicalSize 400×N) to avoid overflow.

## File structure

```
frontend/lib/
  core/routes/app_routes.dart              # MODIFY: add earnings route
  core/routes/app_pages.dart               # MODIFY: register EarningsScreen
  models/earnings/earnings_models.dart     # CREATE: enums + models + EarningsSummary
  shared/widgets/navigation/app_bottom_nav.dart  # CREATE: shared nav + navigateToTab
  features/dashboard/screens/dashboard_screen.dart  # MODIFY: use AppBottomNav
  features/earnings/
    screens/earnings_screen.dart           # CREATE
    widgets/
      period_selector.dart                 # CREATE
      earnings_header.dart                 # CREATE
      total_earnings_card.dart             # CREATE
      delta_chip.dart                      # CREATE
      earnings_breakdown_grid.dart         # CREATE
      earnings_trend_chart.dart            # CREATE
      earnings_history_list.dart           # CREATE
      next_payout_card.dart                # CREATE
frontend/test/... mirrored ...
```

---

### Task 1: Earnings models + route constant

**Files:**
- Create: `frontend/lib/models/earnings/earnings_models.dart`
- Modify: `frontend/lib/core/routes/app_routes.dart`
- Test: `frontend/test/models/earnings/earnings_models_test.dart`

**Interfaces:**
- Produces:
  - `enum EarningsPeriod { thisWeek, lastWeek, thisMonth }` with `String get label` and
    `String get comparisonLabel` ("last week"/"last week"/"last month").
  - `enum DeltaDirection { up, down, flat }`.
  - `EarningsCategory { String label; double amount; double deltaPercent; DeltaDirection get direction; }`
  - `ChartBar { String label; double value; }`
  - `EarningsHistoryEntry { String dateRange; String relativeLabel; double amount; bool paid; }`
  - `PayoutInfo { String bankName; String maskedAccount; double amount; String date; }`
  - `EarningsSummary { EarningsPeriod period; double total; double deltaPercent;
    List<EarningsCategory> categories; List<ChartBar> bars; List<EarningsHistoryEntry> history;
    PayoutInfo payout; double get maxBarValue; factory EarningsSummary.forPeriod(EarningsPeriod); }`
  - top-level `double chartCeiling(double maxValue)` → next multiple of 200, min 200.
  - `AppRoutes.earnings = '/earnings'`.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/models/earnings/earnings_models_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/earnings/earnings_models.dart';

void main() {
  test('chartCeiling rounds up to the next multiple of 200 (min 200)', () {
    expect(chartCeiling(0), 200);
    expect(chartCeiling(200), 200);
    expect(chartCeiling(201), 400);
    expect(chartCeiling(560), 600);
    expect(chartCeiling(2345.50), 2400);
  });

  test('DeltaDirection derives from percent sign', () {
    expect(const EarningsCategory(label: 'a', amount: 1, deltaPercent: 5).direction,
        DeltaDirection.up);
    expect(const EarningsCategory(label: 'a', amount: 1, deltaPercent: -3).direction,
        DeltaDirection.down);
    expect(const EarningsCategory(label: 'a', amount: 1, deltaPercent: 0).direction,
        DeltaDirection.flat);
  });

  test('forPeriod returns documented totals and 4 categories', () {
    final week = EarningsSummary.forPeriod(EarningsPeriod.thisWeek);
    expect(week.total, 2345.50);
    expect(week.deltaPercent, 18);
    expect(week.categories.length, 4);
    expect(week.bars.length, 7);

    final month = EarningsSummary.forPeriod(EarningsPeriod.thisMonth);
    expect(month.total, 7630.75);
    expect(month.bars.length, 4);
  });

  test('category amounts sum to the total for each period', () {
    for (final p in EarningsPeriod.values) {
      final s = EarningsSummary.forPeriod(p);
      final sum = s.categories.fold<double>(0, (a, c) => a + c.amount);
      expect(sum, closeTo(s.total, 0.001), reason: 'period $p');
    }
  });

  test('maxBarValue is a multiple of 200 and >= every bar', () {
    final s = EarningsSummary.forPeriod(EarningsPeriod.thisWeek);
    for (final b in s.bars) {
      expect(s.maxBarValue, greaterThanOrEqualTo(b.value));
    }
    expect(s.maxBarValue % 200, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/models/earnings/earnings_models_test.dart`
Expected: FAIL — file/types not defined.

- [ ] **Step 3: Add the route constant**

In `frontend/lib/core/routes/app_routes.dart`, add after the `dashboard` line:

```dart
  static const dashboard = '/dashboard';
  static const earnings = '/earnings';
```

(Keep the existing `wallet`, `orders`, `profile` constants untouched.)

- [ ] **Step 4: Create the models**

Create `frontend/lib/models/earnings/earnings_models.dart`:

```dart
import 'package:equatable/equatable.dart';

enum EarningsPeriod {
  thisWeek,
  lastWeek,
  thisMonth;

  String get label => switch (this) {
        EarningsPeriod.thisWeek => 'This Week',
        EarningsPeriod.lastWeek => 'Last Week',
        EarningsPeriod.thisMonth => 'This Month',
      };

  String get comparisonLabel =>
      this == EarningsPeriod.thisMonth ? 'last month' : 'last week';
}

enum DeltaDirection { up, down, flat }

DeltaDirection _directionFor(double percent) {
  if (percent > 0) return DeltaDirection.up;
  if (percent < 0) return DeltaDirection.down;
  return DeltaDirection.flat;
}

/// Rounds a chart's max value up to the next multiple of 200 (minimum 200).
double chartCeiling(double maxValue) {
  if (maxValue <= 200) return 200;
  return (maxValue / 200).ceil() * 200;
}

class EarningsCategory extends Equatable {
  final String label;
  final double amount;
  final double deltaPercent;

  const EarningsCategory({
    required this.label,
    required this.amount,
    required this.deltaPercent,
  });

  DeltaDirection get direction => _directionFor(deltaPercent);

  @override
  List<Object?> get props => [label, amount, deltaPercent];
}

class ChartBar extends Equatable {
  final String label;
  final double value;

  const ChartBar({required this.label, required this.value});

  @override
  List<Object?> get props => [label, value];
}

class EarningsHistoryEntry extends Equatable {
  final String dateRange;
  final String relativeLabel;
  final double amount;
  final bool paid;

  const EarningsHistoryEntry({
    required this.dateRange,
    required this.relativeLabel,
    required this.amount,
    required this.paid,
  });

  @override
  List<Object?> get props => [dateRange, relativeLabel, amount, paid];
}

class PayoutInfo extends Equatable {
  final String bankName;
  final String maskedAccount;
  final double amount;
  final String date;

  const PayoutInfo({
    required this.bankName,
    required this.maskedAccount,
    required this.amount,
    required this.date,
  });

  @override
  List<Object?> get props => [bankName, maskedAccount, amount, date];
}

class EarningsSummary extends Equatable {
  final EarningsPeriod period;
  final double total;
  final double deltaPercent;
  final List<EarningsCategory> categories;
  final List<ChartBar> bars;
  final List<EarningsHistoryEntry> history;
  final PayoutInfo payout;

  const EarningsSummary({
    required this.period,
    required this.total,
    required this.deltaPercent,
    required this.categories,
    required this.bars,
    required this.history,
    required this.payout,
  });

  double get maxBarValue {
    final peak = bars.fold<double>(0, (m, b) => b.value > m ? b.value : m);
    return chartCeiling(peak);
  }

  static const _history = [
    EarningsHistoryEntry(
        dateRange: '5 May – 11 May 2025',
        relativeLabel: 'This Week',
        amount: 2345.50,
        paid: true),
    EarningsHistoryEntry(
        dateRange: '28 Apr – 4 May 2025',
        relativeLabel: 'Last Week',
        amount: 1987.75,
        paid: true),
    EarningsHistoryEntry(
        dateRange: '21 Apr – 27 Apr 2025',
        relativeLabel: '2 Weeks Ago',
        amount: 1765.00,
        paid: true),
    EarningsHistoryEntry(
        dateRange: '14 Apr – 20 Apr 2025',
        relativeLabel: '3 Weeks Ago',
        amount: 1532.50,
        paid: true),
  ];

  factory EarningsSummary.forPeriod(EarningsPeriod period) {
    switch (period) {
      case EarningsPeriod.thisWeek:
        return const EarningsSummary(
          period: EarningsPeriod.thisWeek,
          total: 2345.50,
          deltaPercent: 18,
          categories: [
            EarningsCategory(
                label: 'Delivery Earnings', amount: 1890, deltaPercent: 16),
            EarningsCategory(label: 'Incentives', amount: 320, deltaPercent: 25),
            EarningsCategory(
                label: 'Distance Pay', amount: 105.50, deltaPercent: 10),
            EarningsCategory(
                label: 'Other Earnings', amount: 30, deltaPercent: 0),
          ],
          bars: [
            ChartBar(label: 'Mon', value: 280),
            ChartBar(label: 'Tue', value: 310),
            ChartBar(label: 'Wed', value: 420),
            ChartBar(label: 'Thu', value: 560),
            ChartBar(label: 'Fri', value: 340),
            ChartBar(label: 'Sat', value: 275),
            ChartBar(label: 'Sun', value: 160),
          ],
          history: _history,
          payout: PayoutInfo(
              bankName: 'HDFC Bank',
              maskedAccount: '4321',
              amount: 2345.50,
              date: '15 May 2025'),
        );
      case EarningsPeriod.lastWeek:
        return const EarningsSummary(
          period: EarningsPeriod.lastWeek,
          total: 1987.75,
          deltaPercent: 12,
          categories: [
            EarningsCategory(
                label: 'Delivery Earnings', amount: 1590, deltaPercent: 10),
            EarningsCategory(label: 'Incentives', amount: 270, deltaPercent: 18),
            EarningsCategory(
                label: 'Distance Pay', amount: 97.75, deltaPercent: 8),
            EarningsCategory(
                label: 'Other Earnings', amount: 30, deltaPercent: 0),
          ],
          bars: [
            ChartBar(label: 'Mon', value: 230),
            ChartBar(label: 'Tue', value: 260),
            ChartBar(label: 'Wed', value: 340),
            ChartBar(label: 'Thu', value: 450),
            ChartBar(label: 'Fri', value: 300),
            ChartBar(label: 'Sat', value: 220),
            ChartBar(label: 'Sun', value: 187.75),
          ],
          history: _history,
          payout: PayoutInfo(
              bankName: 'HDFC Bank',
              maskedAccount: '4321',
              amount: 1987.75,
              date: '15 May 2025'),
        );
      case EarningsPeriod.thisMonth:
        return const EarningsSummary(
          period: EarningsPeriod.thisMonth,
          total: 7630.75,
          deltaPercent: 22,
          categories: [
            EarningsCategory(
                label: 'Delivery Earnings', amount: 6100, deltaPercent: 20),
            EarningsCategory(
                label: 'Incentives', amount: 1050, deltaPercent: 28),
            EarningsCategory(
                label: 'Distance Pay', amount: 400.75, deltaPercent: 12),
            EarningsCategory(
                label: 'Other Earnings', amount: 80, deltaPercent: 0),
          ],
          bars: [
            ChartBar(label: 'W1', value: 1532.50),
            ChartBar(label: 'W2', value: 1765),
            ChartBar(label: 'W3', value: 1987.75),
            ChartBar(label: 'W4', value: 2345.50),
          ],
          history: _history,
          payout: PayoutInfo(
              bankName: 'HDFC Bank',
              maskedAccount: '4321',
              amount: 2345.50,
              date: '15 May 2025'),
        );
    }
  }

  @override
  List<Object?> get props =>
      [period, total, deltaPercent, categories, bars, history, payout];
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd frontend && flutter test test/models/earnings/earnings_models_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/models/earnings/earnings_models.dart frontend/lib/core/routes/app_routes.dart frontend/test/models/earnings/earnings_models_test.dart
git commit -m "Add earnings mock models and /earnings route constant"
```

---

### Task 2: DeltaChip + PeriodSelector

**Files:**
- Create: `frontend/lib/features/earnings/widgets/delta_chip.dart`
- Create: `frontend/lib/features/earnings/widgets/period_selector.dart`
- Test: `frontend/test/features/earnings/widgets/period_selector_test.dart`

**Interfaces:**
- Consumes: `EarningsPeriod`, `DeltaDirection` (Task 1).
- Produces:
  - `DeltaChip({required double percent, bool compact = false})` — icon + colored "N%" text.
  - `PeriodSelector({required EarningsPeriod value, required ValueChanged<EarningsPeriod> onChanged})`
    — pill showing calendar icon + `value.label` + chevron; tapping opens a menu of the three
    periods and calls `onChanged` on selection.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/earnings/widgets/period_selector_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/earnings/widgets/period_selector.dart';
import 'package:delivery_partner_app/models/earnings/earnings_models.dart';

void main() {
  testWidgets('shows the current period label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PeriodSelector(
            value: EarningsPeriod.thisWeek, onChanged: (_) {}),
      ),
    ));
    expect(find.text('This Week'), findsOneWidget);
  });

  testWidgets('selecting a period from the menu fires onChanged', (tester) async {
    EarningsPeriod? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PeriodSelector(
            value: EarningsPeriod.thisWeek, onChanged: (p) => picked = p),
      ),
    ));
    await tester.tap(find.text('This Week'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This Month').last);
    await tester.pumpAndSettle();
    expect(picked, EarningsPeriod.thisMonth);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/earnings/widgets/period_selector_test.dart`
Expected: FAIL — files not defined.

- [ ] **Step 3: Create DeltaChip**

Create `frontend/lib/features/earnings/widgets/delta_chip.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/earnings/earnings_models.dart';

class DeltaChip extends StatelessWidget {
  final double percent;
  final bool compact;

  const DeltaChip({super.key, required this.percent, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final direction = _directionFor(percent);
    final (icon, color) = switch (direction) {
      DeltaDirection.up => (LucideIcons.trendingUp, AppColors.success),
      DeltaDirection.down => (LucideIcons.trendingDown, AppColors.error),
      DeltaDirection.flat => (LucideIcons.minus, AppColors.textSecondary),
    };
    final magnitude = percent.abs();
    final text = magnitude == magnitude.roundToDouble()
        ? '${magnitude.toStringAsFixed(0)}%'
        : '${magnitude.toStringAsFixed(1)}%';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 12 : 14, color: color),
        const SizedBox(width: 2),
        Text(text,
            style: (compact ? AppTypography.caption : AppTypography.bodyMedium)
                .copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  static DeltaDirection _directionFor(double percent) {
    if (percent > 0) return DeltaDirection.up;
    if (percent < 0) return DeltaDirection.down;
    return DeltaDirection.flat;
  }
}
```

- [ ] **Step 4: Create PeriodSelector**

Create `frontend/lib/features/earnings/widgets/period_selector.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/earnings/earnings_models.dart';

class PeriodSelector extends StatelessWidget {
  final EarningsPeriod value;
  final ValueChanged<EarningsPeriod> onChanged;

  const PeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<EarningsPeriod>(
      onSelected: onChanged,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control)),
      itemBuilder: (context) => [
        for (final p in EarningsPeriod.values)
          PopupMenuItem(
            value: p,
            child: Text(p.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: p == value ? AppColors.primary : AppColors.textPrimary,
                )),
          ),
      ],
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
            const Icon(LucideIcons.calendar,
                size: 16, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(value.label, style: AppTypography.bodyMedium),
            const Icon(LucideIcons.chevronDown,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd frontend && flutter test test/features/earnings/widgets/period_selector_test.dart`
Expected: PASS. (The menu shows all three labels; tapping "This Month" — `.last` disambiguates
from the closed-state label — fires `onChanged`.)

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/earnings/widgets/delta_chip.dart frontend/lib/features/earnings/widgets/period_selector.dart frontend/test/features/earnings/widgets/period_selector_test.dart
git commit -m "Add DeltaChip and PeriodSelector widgets"
```

---

### Task 3: EarningsTrendChart (custom bar chart)

**Files:**
- Create: `frontend/lib/features/earnings/widgets/earnings_trend_chart.dart`
- Test: `frontend/test/features/earnings/widgets/earnings_trend_chart_test.dart`

**Interfaces:**
- Consumes: `ChartBar`, `EarningsPeriod`, `PeriodSelector` (Task 2), `CurrencyFormatter`.
- Produces: `EarningsTrendChart({required List<ChartBar> bars, required double maxValue,
  required EarningsPeriod period, required ValueChanged<EarningsPeriod> onPeriodChanged})` —
  card with title + selector and a hand-built animated bar chart.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/earnings/widgets/earnings_trend_chart_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/earnings/widgets/earnings_trend_chart.dart';
import 'package:delivery_partner_app/models/earnings/earnings_models.dart';

void main() {
  testWidgets('renders one label per bar and the section title', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bars = EarningsSummary.forPeriod(EarningsPeriod.thisWeek).bars;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EarningsTrendChart(
          bars: bars,
          maxValue: 600,
          period: EarningsPeriod.thisWeek,
          onPeriodChanged: (_) {},
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Earnings Trend'), findsOneWidget);
    for (final b in bars) {
      expect(find.text(b.label), findsOneWidget);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/earnings/widgets/earnings_trend_chart_test.dart`
Expected: FAIL — file not defined.

- [ ] **Step 3: Implement EarningsTrendChart**

Create `frontend/lib/features/earnings/widgets/earnings_trend_chart.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/earnings/earnings_models.dart';
import 'period_selector.dart';

class EarningsTrendChart extends StatelessWidget {
  final List<ChartBar> bars;
  final double maxValue;
  final EarningsPeriod period;
  final ValueChanged<EarningsPeriod> onPeriodChanged;

  const EarningsTrendChart({
    super.key,
    required this.bars,
    required this.maxValue,
    required this.period,
    required this.onPeriodChanged,
  });

  static const double _plotHeight = 150;

  @override
  Widget build(BuildContext context) {
    final peak = bars.fold<double>(0, (m, b) => b.value > m ? b.value : m);
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Earnings Trend', style: AppTypography.h2),
              PeriodSelector(value: period, onChanged: onPeriodChanged),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: _plotHeight + 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _YAxis(maxValue: maxValue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        bottom: 20,
                        child: CustomPaint(painter: _GridPainter(maxValue)),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final bar in bars)
                            Expanded(
                              child: _Bar(
                                bar: bar,
                                maxValue: maxValue,
                                plotHeight: _plotHeight,
                                highlighted: bar.value == peak,
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
        ],
      ),
    );
  }
}

class _YAxis extends StatelessWidget {
  final double maxValue;
  const _YAxis({required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final ticks = <double>[maxValue, maxValue * 0.75, maxValue * 0.5, maxValue * 0.25, 0];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final t in ticks)
            Text(CurrencyFormatter.rupees(t),
                style: AppTypography.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final ChartBar bar;
  final double maxValue;
  final double plotHeight;
  final bool highlighted;

  const _Bar({
    required this.bar,
    required this.maxValue,
    required this.plotHeight,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue == 0 ? 0.0 : (bar.value / maxValue).clamp(0.0, 1.0);
    return Semantics(
      label: '${bar.label}, ${CurrencyFormatter.rupeesPrecise(bar.value)}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(CurrencyFormatter.rupees(bar.value),
              style: AppTypography.caption.copyWith(fontSize: 9)),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, t, child) => Container(
              width: 14,
              height: plotHeight * t,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.ctaGradient,
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: highlighted ? AppShadows.cta : null,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 14,
            child: Text(bar.label,
                style: AppTypography.caption.copyWith(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double maxValue;
  _GridPainter(this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.maxValue != maxValue;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/earnings/widgets/earnings_trend_chart_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/earnings/widgets/earnings_trend_chart.dart frontend/test/features/earnings/widgets/earnings_trend_chart_test.dart
git commit -m "Add custom-painted EarningsTrendChart"
```

---

### Task 4: TotalEarningsCard + EarningsBreakdownGrid

**Files:**
- Create: `frontend/lib/features/earnings/widgets/total_earnings_card.dart`
- Create: `frontend/lib/features/earnings/widgets/earnings_breakdown_grid.dart`
- Test: `frontend/test/features/earnings/widgets/earnings_summary_widgets_test.dart`

**Interfaces:**
- Consumes: `EarningsCategory` (Task 1), `DeltaChip` (Task 2), `CurrencyFormatter`.
- Produces:
  - `TotalEarningsCard({required double total, required double deltaPercent, required String comparisonLabel})`
    — gradient card: "Total Earnings", big precise amount, delta line, wallet motif.
  - `EarningsBreakdownGrid({required List<EarningsCategory> categories})` — 2×2 grid of cells
    (icon, label, amount, `DeltaChip`).

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/earnings/widgets/earnings_summary_widgets_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/earnings/widgets/total_earnings_card.dart';
import 'package:delivery_partner_app/features/earnings/widgets/earnings_breakdown_grid.dart';
import 'package:delivery_partner_app/models/earnings/earnings_models.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('TotalEarningsCard shows total and comparison', (tester) async {
    await tester.pumpWidget(wrap(const TotalEarningsCard(
      total: 2345.50,
      deltaPercent: 18,
      comparisonLabel: 'last week',
    )));
    expect(find.text('₹2,345.50'), findsOneWidget);
    expect(find.text('Total Earnings'), findsOneWidget);
    expect(find.textContaining('last week'), findsOneWidget);
  });

  testWidgets('EarningsBreakdownGrid renders all category labels and amounts',
      (tester) async {
    final cats = EarningsSummary.forPeriod(EarningsPeriod.thisWeek).categories;
    await tester.pumpWidget(wrap(EarningsBreakdownGrid(categories: cats)));
    expect(find.text('Delivery Earnings'), findsOneWidget);
    expect(find.text('Incentives'), findsOneWidget);
    expect(find.text('₹1,890.00'), findsOneWidget);
    expect(find.text('₹320.00'), findsOneWidget);
  });
}
```

Note: `CurrencyFormatter.rupeesPrecise(2345.5)` yields `"₹2,345.50"` only if the formatter
groups thousands. The existing formatter does NOT group (it returns `"₹2345.50"`). **Before
writing widgets, extend the formatter** — see Step 3.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/earnings/widgets/earnings_summary_widgets_test.dart`
Expected: FAIL — files not defined.

- [ ] **Step 3: Add thousands grouping to the formatter**

The mockup shows grouped amounts (₹2,345.50, ₹1,890.00). Update
`frontend/lib/core/utils/currency_formatter.dart` to group the integer part with commas
(Indian or Western grouping is acceptable; use Western thousands grouping for simplicity):

```dart
class CurrencyFormatter {
  CurrencyFormatter._();

  static String rupees(num amount) => '₹${_group(amount.toStringAsFixed(0))}';

  static String rupeesPrecise(num amount) {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    return '₹${_group(parts[0])}.${parts[1]}';
  }

  static String _group(String integerDigits) {
    final negative = integerDigits.startsWith('-');
    final digits = negative ? integerDigits.substring(1) : integerDigits;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '${negative ? '-' : ''}$buffer';
  }
}
```

Note: this changes `rupees`/`rupeesPrecise` output for values ≥ 1000 across the app
(e.g. the Home "Today's Earnings ₹920.50" is unaffected; any ≥1000 value now groups). This is
a desired global improvement. Existing Home tests assert values < 1000 (₹38.50, ₹920.50), so
they remain green — verify in Task 7.

- [ ] **Step 4: Create TotalEarningsCard**

Create `frontend/lib/features/earnings/widgets/total_earnings_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import 'delta_chip.dart';

class TotalEarningsCard extends StatelessWidget {
  final double total;
  final double deltaPercent;
  final String comparisonLabel;

  const TotalEarningsCard({
    super.key,
    required this.total,
    required this.deltaPercent,
    required this.comparisonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Earnings',
                    style:
                        AppTypography.caption.copyWith(color: Colors.white70)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  CurrencyFormatter.rupeesPrecise(total),
                  style: AppTypography.display.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    DeltaChip(percent: deltaPercent),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text('more than $comparisonLabel',
                          style: AppTypography.caption
                              .copyWith(color: Colors.white70)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: const Icon(LucideIcons.wallet, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}
```

Note: `DeltaChip` colors are success/error; on the dark gradient the up-arrow green
(`AppColors.success`) remains legible. Acceptable per the design.

- [ ] **Step 5: Create EarningsBreakdownGrid**

Create `frontend/lib/features/earnings/widgets/earnings_breakdown_grid.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/earnings/earnings_models.dart';
import 'delta_chip.dart';

class EarningsBreakdownGrid extends StatelessWidget {
  final List<EarningsCategory> categories;

  const EarningsBreakdownGrid({super.key, required this.categories});

  static const _icons = [
    LucideIcons.bike,
    LucideIcons.gift,
    LucideIcons.mapPin,
    LucideIcons.circleDollarSign,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var i = 0; i < categories.length; i++)
              SizedBox(
                width: cellWidth,
                child: _Cell(
                  category: categories[i],
                  icon: _icons[i % _icons.length],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  final EarningsCategory category;
  final IconData icon;

  const _Cell({required this.category, required this.icon});

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
              Icon(icon, size: 18, color: AppColors.secondary),
              const Spacer(),
              DeltaChip(percent: category.deltaPercent, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(CurrencyFormatter.rupeesPrecise(category.amount),
              style: AppTypography.numericMd),
          const SizedBox(height: 2),
          Text(category.label,
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd frontend && flutter test test/features/earnings/widgets/earnings_summary_widgets_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/earnings/widgets/total_earnings_card.dart frontend/lib/features/earnings/widgets/earnings_breakdown_grid.dart frontend/lib/core/utils/currency_formatter.dart frontend/test/features/earnings/widgets/earnings_summary_widgets_test.dart
git commit -m "Add TotalEarningsCard, EarningsBreakdownGrid, and grouped currency formatting"
```

---

### Task 5: EarningsHeader + EarningsHistoryList + NextPayoutCard

**Files:**
- Create: `frontend/lib/features/earnings/widgets/earnings_header.dart`
- Create: `frontend/lib/features/earnings/widgets/earnings_history_list.dart`
- Create: `frontend/lib/features/earnings/widgets/next_payout_card.dart`
- Test: `frontend/test/features/earnings/widgets/earnings_sections_test.dart`

**Interfaces:**
- Consumes: `EarningsPeriod`, `EarningsHistoryEntry`, `PayoutInfo` (Task 1),
  `PeriodSelector` (Task 2), `StatusChip`, `CurrencyFormatter`.
- Produces:
  - `EarningsHeader({required EarningsPeriod period, required ValueChanged<EarningsPeriod> onPeriodChanged})`
    — logo/subtitle row + `PeriodSelector`, then the "Earnings" title.
  - `EarningsHistoryList({required List<EarningsHistoryEntry> history, VoidCallback? onViewAll})`.
  - `NextPayoutCard({required PayoutInfo payout})`.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/earnings/widgets/earnings_sections_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/earnings/widgets/earnings_header.dart';
import 'package:delivery_partner_app/features/earnings/widgets/earnings_history_list.dart';
import 'package:delivery_partner_app/features/earnings/widgets/next_payout_card.dart';
import 'package:delivery_partner_app/models/earnings/earnings_models.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('EarningsHeader shows title and current period', (tester) async {
    await tester.pumpWidget(wrap(EarningsHeader(
        period: EarningsPeriod.thisWeek, onPeriodChanged: (_) {})));
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
  });

  testWidgets('EarningsHistoryList renders each entry with a Paid chip',
      (tester) async {
    final history = EarningsSummary.forPeriod(EarningsPeriod.thisWeek).history;
    await tester.pumpWidget(wrap(EarningsHistoryList(history: history)));
    expect(find.text('5 May – 11 May 2025'), findsOneWidget);
    expect(find.text('Paid'), findsNWidgets(history.length));
  });

  testWidgets('NextPayoutCard shows bank, amount and date', (tester) async {
    const payout = PayoutInfo(
        bankName: 'HDFC Bank',
        maskedAccount: '4321',
        amount: 2345.50,
        date: '15 May 2025');
    await tester.pumpWidget(wrap(const NextPayoutCard(payout: payout)));
    expect(find.text('Next Payout'), findsOneWidget);
    expect(find.textContaining('4321'), findsOneWidget);
    expect(find.text('₹2,345.50'), findsOneWidget);
    expect(find.text('15 May 2025'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/earnings/widgets/earnings_sections_test.dart`
Expected: FAIL — files not defined.

- [ ] **Step 3: Create EarningsHeader**

Create `frontend/lib/features/earnings/widgets/earnings_header.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/earnings/earnings_models.dart';
import 'period_selector.dart';

class EarningsHeader extends StatelessWidget {
  final EarningsPeriod period;
  final ValueChanged<EarningsPeriod> onPeriodChanged;

  const EarningsHeader({
    super.key,
    required this.period,
    required this.onPeriodChanged,
  });

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
            PeriodSelector(value: period, onChanged: onPeriodChanged),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Earnings', style: AppTypography.h1),
      ],
    );
  }
}
```

- [ ] **Step 4: Create EarningsHistoryList**

Create `frontend/lib/features/earnings/widgets/earnings_history_list.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/earnings/earnings_models.dart';
import '../../../shared/widgets/chips/status_chip.dart';

class EarningsHistoryList extends StatelessWidget {
  final List<EarningsHistoryEntry> history;
  final VoidCallback? onViewAll;

  const EarningsHistoryList({super.key, required this.history, this.onViewAll});

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Earnings History', style: AppTypography.h2),
              GestureDetector(
                onTap: onViewAll,
                child: Row(
                  children: [
                    Text('View All',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.primary)),
                    const Icon(LucideIcons.chevronRight,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < history.length; i++) ...[
            if (i > 0) const Divider(height: AppSpacing.lg, color: AppColors.border),
            _HistoryRow(entry: history[i]),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final EarningsHistoryEntry entry;
  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: const Icon(LucideIcons.calendarCheck,
              size: 18, color: AppColors.success),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.dateRange, style: AppTypography.bodyMedium),
              Text(entry.relativeLabel, style: AppTypography.caption),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(CurrencyFormatter.rupeesPrecise(entry.amount),
            style: AppTypography.bodyMedium),
        const SizedBox(width: AppSpacing.sm),
        StatusChip(
          label: entry.paid ? 'Paid' : 'Pending',
          color: entry.paid ? AppColors.success : AppColors.warning,
          background: entry.paid ? AppColors.successBg : AppColors.warningBg,
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Create NextPayoutCard**

Create `frontend/lib/features/earnings/widgets/next_payout_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/earnings/earnings_models.dart';

class NextPayoutCard extends StatelessWidget {
  final PayoutInfo payout;

  const NextPayoutCard({super.key, required this.payout});

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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: const Icon(LucideIcons.landmark, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next Payout', style: AppTypography.bodyMedium),
                Text('Transfers to your account',
                    style: AppTypography.caption),
                const SizedBox(height: 2),
                Text('${payout.bankName} ····${payout.maskedAccount}',
                    style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(CurrencyFormatter.rupeesPrecise(payout.amount),
                  style: AppTypography.numericMd.copyWith(color: AppColors.primary)),
              Text(payout.date, style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd frontend && flutter test test/features/earnings/widgets/earnings_sections_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/earnings/widgets/earnings_header.dart frontend/lib/features/earnings/widgets/earnings_history_list.dart frontend/lib/features/earnings/widgets/next_payout_card.dart frontend/test/features/earnings/widgets/earnings_sections_test.dart
git commit -m "Add EarningsHeader, EarningsHistoryList, and NextPayoutCard"
```

---

### Task 6: AppBottomNav + EarningsScreen + route wiring

**Files:**
- Create: `frontend/lib/shared/widgets/navigation/app_bottom_nav.dart`
- Create: `frontend/lib/features/earnings/screens/earnings_screen.dart`
- Modify: `frontend/lib/features/dashboard/screens/dashboard_screen.dart`
- Modify: `frontend/lib/core/routes/app_pages.dart`
- Test: `frontend/test/features/earnings/screens/earnings_screen_test.dart`

**Interfaces:**
- Consumes: all earnings widgets (Tasks 2–5), `EarningsSummary` (Task 1), `FloatingBottomNav`,
  `NavItem`, `ResponsiveFrame`, `AppRoutes`.
- Produces:
  - `AppBottomNav({required int currentIndex})` — the shared 4-tab nav; taps call
    `navigateToTab(int)`.
  - top-level `void navigateToTab(int index)` — `Get.offNamed` to the tab's route unless
    already there.
  - `EarningsScreen` (`StatefulWidget`) at `AppRoutes.earnings`.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/earnings/screens/earnings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/earnings/screens/earnings_screen.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp() => GetMaterialApp(
      initialRoute: AppRoutes.earnings,
      getPages: [
        GetPage(name: AppRoutes.earnings, page: () => const EarningsScreen()),
        GetPage(
            name: AppRoutes.dashboard,
            page: () => const Scaffold(body: Text('Dashboard Screen'))),
        GetPage(
            name: AppRoutes.orders,
            page: () => const Scaffold(body: Text('Orders Screen'))),
        GetPage(
            name: AppRoutes.profile,
            page: () => const Scaffold(body: Text('Profile Screen'))),
      ],
    );

void main() {
  testWidgets('renders this-week total by default', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('₹2,345.50'), findsWidgets);
  });

  testWidgets('switching period updates the total', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('This Week').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('This Month').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('₹7,630.75'), findsWidgets);
  });

  testWidgets('tapping the Home tab navigates to the dashboard', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Screen'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/earnings/screens/earnings_screen_test.dart`
Expected: FAIL — `EarningsScreen` / `AppBottomNav` not defined.

- [ ] **Step 3: Create AppBottomNav**

Create `frontend/lib/shared/widgets/navigation/app_bottom_nav.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import 'floating_bottom_nav.dart';

const _tabRoutes = [
  AppRoutes.dashboard,
  AppRoutes.earnings,
  AppRoutes.orders,
  AppRoutes.profile,
];

void navigateToTab(int index) {
  final route = _tabRoutes[index];
  if (Get.currentRoute != route) {
    Get.offNamed(route);
  }
}

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return FloatingBottomNav(
      currentIndex: currentIndex,
      onTap: navigateToTab,
      items: const [
        NavItem(
            icon: LucideIcons.home, activeIcon: LucideIcons.home, label: 'Home'),
        NavItem(
            icon: LucideIcons.indianRupee,
            activeIcon: LucideIcons.indianRupee,
            label: 'Earnings'),
        NavItem(
            icon: LucideIcons.receipt,
            activeIcon: LucideIcons.receipt,
            label: 'Orders'),
        NavItem(
            icon: LucideIcons.user, activeIcon: LucideIcons.user, label: 'Profile'),
      ],
    );
  }
}
```

- [ ] **Step 4: Point the dashboard at AppBottomNav**

In `frontend/lib/features/dashboard/screens/dashboard_screen.dart`:

1. Add import:

```dart
import '../../../shared/widgets/navigation/app_bottom_nav.dart';
```

2. Replace the `if (showNav) _BottomNav(activeIndex: _isDelivered ? 2 : 0),` line with:

```dart
              if (showNav) const AppBottomNav(currentIndex: 0),
```

3. Delete the entire private `_BottomNav` class at the bottom of the file and remove the now-unused
   `import 'package:lucide_icons/lucide_icons.dart';` and
   `import '../../../shared/widgets/navigation/floating_bottom_nav.dart';` **only if** no other code
   in the file references them (the shell body does not — verify with `flutter analyze` in Step 8).

- [ ] **Step 5: Register the route**

In `frontend/lib/core/routes/app_pages.dart`:

1. Add import:

```dart
import '../../features/earnings/screens/earnings_screen.dart';
```

2. Add a page registration next to the dashboard entry:

```dart
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),
    GetPage(name: AppRoutes.earnings, page: () => const EarningsScreen()),
```

- [ ] **Step 6: Create EarningsScreen**

Create `frontend/lib/features/earnings/screens/earnings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/earnings/earnings_models.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/app_bottom_nav.dart';
import '../widgets/earnings_breakdown_grid.dart';
import '../widgets/earnings_header.dart';
import '../widgets/earnings_history_list.dart';
import '../widgets/earnings_trend_chart.dart';
import '../widgets/next_payout_card.dart';
import '../widgets/total_earnings_card.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  EarningsPeriod _period = EarningsPeriod.thisWeek;

  void _setPeriod(EarningsPeriod p) => setState(() => _period = p);

  @override
  Widget build(BuildContext context) {
    final summary = EarningsSummary.forPeriod(_period);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EarningsHeader(
                          period: _period, onPeriodChanged: _setPeriod),
                      const SizedBox(height: AppSpacing.md),
                      TotalEarningsCard(
                        total: summary.total,
                        deltaPercent: summary.deltaPercent,
                        comparisonLabel: _period.comparisonLabel,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      EarningsBreakdownGrid(categories: summary.categories),
                      const SizedBox(height: AppSpacing.md),
                      EarningsTrendChart(
                        bars: summary.bars,
                        maxValue: summary.maxBarValue,
                        period: _period,
                        onPeriodChanged: _setPeriod,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      EarningsHistoryList(history: summary.history),
                      const SizedBox(height: AppSpacing.md),
                      NextPayoutCard(payout: summary.payout),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              const AppBottomNav(currentIndex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Run the screen tests to verify they pass**

Run: `cd frontend && flutter test test/features/earnings/screens/earnings_screen_test.dart`
Expected: PASS (3 tests). If the period menu tap is ambiguous, the `.first`/`.last` qualifiers
in the test disambiguate the pill label from the menu item.

- [ ] **Step 8: Analyze the touched libraries**

Run: `cd frontend && flutter analyze lib/features/earnings lib/features/dashboard lib/shared/widgets/navigation lib/models/earnings lib/core`
Expected: No issues. Remove any unused-import warnings the analyzer flags in
`dashboard_screen.dart`.

- [ ] **Step 9: Commit**

```bash
git add frontend/lib/shared/widgets/navigation/app_bottom_nav.dart frontend/lib/features/earnings/screens/earnings_screen.dart frontend/lib/features/dashboard/screens/dashboard_screen.dart frontend/lib/core/routes/app_pages.dart frontend/test/features/earnings/screens/earnings_screen_test.dart
git commit -m "Add EarningsScreen, shared AppBottomNav, and wire tab navigation"
```

---

### Task 7: Full-suite verification

**Files:** Verify only.

- [ ] **Step 1: Run the entire test suite**

Run: `cd frontend && flutter test`
Expected: All tests PASS, including the pre-existing Home/dashboard tests (they assert
sub-1000 amounts — ₹38.50, ₹920.50 — which the new grouped formatter leaves unchanged) and
the earnings tests. If any Home test asserted a ≥1000 amount without grouping, update it to the
grouped form and note it in the commit.

- [ ] **Step 2: Analyze the whole project**

Run: `cd frontend && flutter analyze`
Expected: No new errors/warnings from this work (a pre-existing info-level lint in
`document_upload_actions.dart` is unrelated and may remain).

- [ ] **Step 3: Commit any cleanup**

```bash
git add -A
git commit -m "Verify full suite after Earnings screen"
```

---

## Self-Review Notes

- **Spec coverage:** models + `forPeriod` + route (Task 1), PeriodSelector + delta (Task 2),
  custom bar chart (Task 3), total card + breakdown grid (Task 4), header + history + payout
  (Task 5), screen assembly + shared nav wiring + `/earnings` route (Task 6), full verification
  (Task 7). Functional period toggle covered by the EarningsScreen test; accessibility via
  `Semantics` on bars and icon+text deltas.
- **Placeholder scan:** none — every step has full code.
- **Type consistency:** `EarningsPeriod.label`/`comparisonLabel`, `EarningsSummary.forPeriod`,
  `maxBarValue`, `chartCeiling`, `DeltaChip(percent, compact)`, `PeriodSelector(value, onChanged)`,
  `EarningsTrendChart(bars, maxValue, period, onPeriodChanged)`, `TotalEarningsCard(total,
  deltaPercent, comparisonLabel)`, `EarningsBreakdownGrid(categories)`, `EarningsHistoryList(history,
  onViewAll)`, `NextPayoutCard(payout)`, `AppBottomNav(currentIndex)`, `navigateToTab(index)`,
  `FloatingBottomNav(currentIndex, onTap, items)`, `StatusChip(label, color, background)` all match.
- **Known deviation:** the spec described the breakdown grid nested inside the total card; the plan
  renders them as adjacent siblings (`TotalEarningsCard` then `EarningsBreakdownGrid`) for cleaner,
  independently-testable widgets. Visual result matches the mockup's stacked layout.
- **Cross-feature effect:** currency grouping now applies app-wide (Task 4 Step 3); verified safe for
  existing sub-1000 Home assertions in Task 7.
