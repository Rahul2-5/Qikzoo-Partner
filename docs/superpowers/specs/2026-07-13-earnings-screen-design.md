# Earnings Screen — Design

## Context

Second tab of the Delivery Partner app's bottom navigation (Home was built first —
see `2026-07-13-home-screen-order-flow-design.md`). The mockup shows a single scrollable
screen: total earnings with a category breakdown, a weekly bar chart, an earnings-history
list, and a next-payout card. The codebase has a thin Riverpod wallet layer
(`WalletModel` = balance/pending, `walletProvider`, `MockWalletRepository`) but the
`features/wallet/` and earnings screens are empty.

Decisions from brainstorming:

- **State**: pure `setState` mock, matching the Home screen. No Riverpod wiring; the
  existing wallet layer is left untouched for a later pass.
- **Navigation**: a standalone `EarningsScreen` at a new `/earnings` route, plus wiring the
  shared bottom nav so tapping tabs actually switches screens (currently the dashboard's nav
  taps are no-ops). Route-based switching via `Get.offNamed` (each screen renders its own
  nav with the correct active index) — chosen over an IndexedStack shell because the
  dashboard already owns its nav and hides it during active orders; a parent-owned nav would
  fight that logic.
- **Chart**: custom-painted bar chart (no chart package), consistent with the
  no-new-packages convention.
- **Period selector**: functional. Selecting This Week / Last Week / This Month swaps
  between hardcoded mock datasets.
- **Fidelity**: keep the Qikzoo brand (blue/green gradients, light airy cards, existing
  `AppColors`/`AppTypography`/`AppShadows`/`AppSpacing`/`AppRadius` tokens); improve
  hierarchy, spacing, and accessibility freely.

## Scope

In scope: the Earnings screen, its mock models, its widgets, and wiring the shared bottom
nav for Home↔Earnings. Out of scope: real backend, the withdraw/wallet flow (`/wallet`
stays as-is), the Orders and Profile screens (their nav taps route to existing placeholder
routes), and refactoring the Home screen beyond extracting its bottom nav.

## Navigation & shared bottom nav

- Add `AppRoutes.earnings = '/earnings'` and register `EarningsScreen` in `AppPages`.
- Extract the dashboard's private `_BottomNav` into a shared
  `AppBottomNav` (`lib/shared/widgets/navigation/app_bottom_nav.dart`):
  - `AppBottomNav({required int currentIndex})` renders the 4-item `FloatingBottomNav`
    (Home, Earnings, Orders, Profile) and handles taps internally via a top-level helper
    `navigateToTab(int index)`.
  - `navigateToTab` maps: 0 → `AppRoutes.dashboard`, 1 → `AppRoutes.earnings`,
    2 → `AppRoutes.orders`, 3 → `AppRoutes.profile`, using
    `Get.offNamed(route)` (no-op if already on that route, so tapping the current tab does
    nothing). Orders/Profile are existing placeholder routes.
  - `DashboardScreen` replaces its private `_BottomNav` usage with
    `AppBottomNav(currentIndex: 0)` (Home). Its hide-during-active-order logic is unchanged.
- `EarningsScreen` renders `AppBottomNav(currentIndex: 1)`.

## Mock data model (`lib/models/earnings/`)

- `enum EarningsPeriod { thisWeek, lastWeek, thisMonth }` with a `String get label`
  ("This Week" / "Last Week" / "This Month").
- `DeltaDirection { up, down, flat }` derived from a percent value (`>0` up, `<0` down,
  `==0` flat).
- `EarningsCategory` (Equatable): `String label`, `double amount`, `double deltaPercent`;
  `DeltaDirection get direction`.
- `ChartBar` (Equatable): `String label` (e.g. "Mon"), `double value`.
- `EarningsHistoryEntry` (Equatable): `String dateRange` ("5 May – 11 May 2025"),
  `String relativeLabel` ("This Week"), `double amount`, `bool paid`.
- `PayoutInfo` (Equatable): `String bankName` ("HDFC Bank"), `String maskedAccount`
  ("4321"), `double amount`, `String date` ("15 May 2025").
- `EarningsSummary` (Equatable): `EarningsPeriod period`, `double total`,
  `double deltaPercent` (vs previous period), `List<EarningsCategory> categories` (length 4:
  Delivery Earnings, Incentives, Distance Pay, Other Earnings), `List<ChartBar> bars`,
  `List<EarningsHistoryEntry> history`, `PayoutInfo payout`.
  - `double get maxBarValue` → max of bar values (for chart scaling), rounded up to a
    "nice" ceiling (next multiple of 200, min 200) via a `chartCeiling` helper.
  - `factory EarningsSummary.forPeriod(EarningsPeriod)` returns distinct hardcoded data:
    - thisWeek: total 2345.50, delta +18, categories [1890 +16, 320 +25, 105.50 +10,
      30 +0], bars Mon–Sun [280,310,420,560,340,275,160], history = 4 recent weeks (This
      Week 2345.50 paid, Last Week 1987.75 paid, 2 Weeks Ago 1765 paid, 3 Weeks Ago 1532.50
      paid), payout HDFC ····4321, 2345.50, "15 May 2025".
    - lastWeek: total 1987.75, delta +12, categories [1590 +10, 270 +18, 97.75 +8, 30 +0],
      bars Mon–Sun [230,260,340,450,300,220,187.75] (sum 1987.75), same history list,
      payout amount 1987.75.
    - thisMonth: total 7630.75, delta +22, categories [6100 +20, 1050 +28, 400.75 +12,
      80 +0] (sum 7630.75), bars = 4 weekly bars ["W1","W2","W3","W4"] =
      [1532.50,1765,1987.75,2345.50] (sum 7630.75), history same, payout 2345.50.

  The history list is shared across periods (it's an all-time recent history); only total,
  delta, categories, bars, and payout amount change with the period.

## Screen structure

`EarningsScreen` (`StatefulWidget`) holds `EarningsPeriod _period = EarningsPeriod.thisWeek`
and derives `summary = EarningsSummary.forPeriod(_period)` each build.

`Scaffold` (`AppColors.background`) → `SafeArea` → `Column`:
- `Expanded` → `SingleChildScrollView` (`ResponsiveFrame(maxWidth: 520)`,
  `BouncingScrollPhysics`) containing, top-to-bottom, with `AppSpacing.md` gaps:
  1. `EarningsHeader(period: _period, onPeriodChanged: setPeriod)` — logo row +
     `PeriodSelector` on the right, then the "Earnings" title (`AppTypography.h1`).
  2. `TotalEarningsCard(total, deltaPercent, previousLabel)` — gradient card: "Total
     Earnings" caption, big `CurrencyFormatter.rupeesPrecise(total)`, a delta line
     ("↑ 18% more than last week" using `DeltaDirection` icon/color), wallet motif on the
     right (icon-based, no asset). Wrapped so it contains the breakdown grid below the
     divider (mockup shows breakdown nested in the card).
  3. `EarningsBreakdownGrid(categories)` — 2×2 (or 4-in-a-row that wraps) of cells; each:
     small icon, label, `rupeesPrecise(amount)`, delta chip. Uses `Wrap`/`Row+Expanded`.
  4. `EarningsTrendChart(bars, maxBarValue, period, onPeriodChanged)` — card: "Earnings
     Trend" title + `PeriodSelector`; the custom bar chart below.
  5. `EarningsHistoryList(history, onViewAll)` — "Earnings History" + "View All", then
     the week rows.
  6. `NextPayoutCard(payout)` — bank icon, "Next Payout", helper line, masked account,
     amount, date.
  7. bottom padding so content clears the nav.
- `AppBottomNav(currentIndex: 1)`.

`setPeriod(EarningsPeriod p)` → `setState(() => _period = p)`.

## Custom bar chart (`earnings_trend_chart.dart`)

- A `StatelessWidget` card hosting a fixed-height (≈180) chart area.
- Layout: a left gutter of y-axis labels (₹0, ₹200 … up to `maxBarValue`) with faint
  horizontal gridlines, and a `Row` of bars (one per `ChartBar`), each bar an
  `Expanded` column: value label on top (`AppTypography.caption`), a gradient
  `Container` whose height = `barHeight * (value / maxBarValue)` (animated via
  `TweenAnimationBuilder`, 300ms, so switching period grows/shrinks bars), and the day
  label below.
- Gridlines drawn with a lightweight `CustomPaint` background (horizontal lines at each
  y-tick) so bars overlay them. Bar gradient uses `AppColors.ctaGradient`
  (dark teal → bright green), matching the mockup.
- The tallest bar is highlighted (full-opacity gradient); others slightly lower opacity —
  purely decorative, not encoding data.
- Each bar exposes `Semantics(label: '<day>, <rupees>')`.

## Period selector (`period_selector.dart`)

- `PeriodSelector({required EarningsPeriod value, required ValueChanged<EarningsPeriod>
  onChanged})`: a pill (`AppColors.surface`, `AppRadius.chip`, `AppShadows.control`) showing
  a calendar icon + `value.label` + chevron. Tapping opens a menu
  (`showMenu`/`PopupMenuButton` styled, or a simple bottom sheet) listing the three periods;
  selecting one calls `onChanged`.

## Delta indicator (shared inside breakdown + total card)

A small `_DeltaChip`/helper renders `deltaPercent`:
- up → `LucideIcons.trendingUp`, `AppColors.success`, "↑ N%".
- down → `LucideIcons.trendingDown`, `AppColors.error`, "↓ N%".
- flat → `LucideIcons.minus`, `AppColors.textSecondary`, "— 0%".
Always icon + colored text (never color alone).

## Cross-cutting standards

- Touch targets ≥ 48dp (PeriodSelector, View All, history rows, nav items).
- Currency: `CurrencyFormatter.rupeesPrecise` for money with paise (₹2,345.50);
  `rupees` for whole-rupee axis ticks (₹200).
- Colors: green = positive/earnings, red = negative delta, blue = info/bank.
- All animation via `TweenAnimationBuilder` (no controllers to dispose); disposed-safe.
- No new packages. `lucide_icons`, `get`, `equatable` cover everything.
- Wrapped in `SafeArea` + `ResponsiveFrame(maxWidth: 520)`.

## Testing

Widget/unit tests in `frontend/test/`, mirroring `lib/`:

- `EarningsSummary.forPeriod`: returns the documented total/delta per period; `categories`
  has length 4; `maxBarValue` ≥ every bar value and is a multiple of 200; `chartCeiling`
  rounds up correctly (e.g. 560 → 600, 200 → 200, 561 → 600... i.e. next multiple of 200).
- `PeriodSelector`: shows the current label; selecting a menu item fires `onChanged` with
  the chosen period.
- `EarningsTrendChart`: renders one bar per `ChartBar` and the day labels.
- `EarningsHistoryList`: renders a row per entry with amount and a "Paid" chip.
- `EarningsScreen`: switching the period (via the header selector) updates the displayed
  total (e.g. This Week ₹2,345.50 → This Month ₹7,630.75).
- `AppBottomNav`: tapping the Earnings tab from `/dashboard` navigates to `/earnings`
  (pump a `GetMaterialApp` with both routes and assert the Earnings screen shows).
