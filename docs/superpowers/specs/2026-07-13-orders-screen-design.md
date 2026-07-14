# Orders Screen ("My Orders") — Design

## Context

Third tab of the Delivery Partner app's bottom navigation (Home and Earnings built first —
see `2026-07-13-home-screen-order-flow-design.md` and `2026-07-13-earnings-screen-design.md`).
The mockup shows a "My Orders" screen: a header with search/filter actions, four tabs
(All Orders / Upcoming / Completed / Cancelled), and a date-grouped list of order cards, with a
support banner at the bottom.

The `/orders` route already exists as a placeholder, and `AppBottomNav` already routes tab
index 2 there. The codebase has a rich active-flow `OrderModel` (pickup/drop, items, earnings
breakdown) and shared widgets `SearchBarCustom`, `FilterChipCustom`, `StatusChip`,
`EmptyState`.

Decisions from brainstorming:

- **State**: pure `setState` mock, matching Home and Earnings.
- **Model**: a dedicated lightweight `OrderListEntry` (list-oriented) rather than overloading
  the active-flow `OrderModel`.
- **Tabs**: a custom underlined segmented row driving a single date-grouped, filtered list
  (not `TabBar`/`TabBarView`).
- **Card tap / View Details**: a stubbed callback (light snackbar) — a read-only Order Detail
  screen is out of scope and would be its own spec.
- **Search & filter**: functional. Search filters the visible list by restaurant name / order
  ID; the filter icon opens a bottom sheet for sort + date filtering.
- **Fidelity**: keep the Qikzoo brand and existing design tokens; improve hierarchy, spacing,
  and accessibility freely.

## Scope

In scope: the Orders list screen, its mock model, its widgets, registering the `/orders`
route to the real screen, functional tabs + search + filter/sort. Out of scope: a read-only
order-detail screen (tap is stubbed), real backend, and changes to Home/Earnings beyond
registering the route.

## Route wiring

- `AppRoutes.orders = '/orders'` already exists. In `AppPages`, replace the placeholder
  registration with `GetPage(name: AppRoutes.orders, page: () => const OrdersScreen())`.
- `AppBottomNav` already maps index 2 → `/orders`; no nav change needed. `OrdersScreen`
  renders `AppBottomNav(currentIndex: 2)`.

## Mock data model (`lib/models/orders/order_list_entry.dart`)

- `enum OrderListStatus { upcoming, completed, cancelled }`.
- `enum OrderBadge { newOrder, delivered, cancelled }` with `String get label`
  ("New" / "Delivered" / "Cancelled").
- `OrderListEntry` (Equatable):
  `String id`, `String restaurantName`, `String restaurantArea`, `String dropAddress`,
  `double distanceKm`, `String timeAwayLabel` ("12 mins away"), `double amount`,
  `String timeLabel` ("11:30 AM"), `String dateGroup` ("Today, 12 May 2025"),
  `OrderListStatus status`, `OrderBadge badge`.
  - `static List<OrderListEntry> mockList()` returns the mockup's entries plus one cancelled
    sample so every tab has content:
    1. `#171287364912` The Biryani House, Goregaon West → Sundervan Complex, Andheri West;
       4.2 km, "12 mins away"; ₹38.50; 11:30 AM; "Today, 12 May 2025"; upcoming; newOrder.
    2. `#171287124578` The Biryani House, Goregaon West → Lokhandwala Complex, Andheri West;
       4.6 km, "15 mins"; ₹46.00; 10:25 AM; "Today, 12 May 2025"; completed; delivered.
    3. `#171286889341` Burger Point, Versova → Yari Road, Versova; 2.1 km, "8 mins";
       ₹32.50; 09:15 AM; "Today, 12 May 2025"; completed; delivered.
    4. `#171276554801` Pizza Corner, Juhu Tara Road → JVPD Scheme, Juhu; 5.2 km, "18 mins";
       ₹55.00; 08:20 PM; "Yesterday, 11 May 2025"; completed; delivered.
    5. `#171276112233` Cake Studio, Bandra West → Hill Road, Bandra West; 3.0 km, "11 mins";
       ₹0.00; 06:40 PM; "Yesterday, 11 May 2025"; cancelled; cancelled.
- `enum OrdersTab { all, upcoming, completed, cancelled }` with:
  - `String get label` ("All Orders" / "Upcoming" / "Completed" / "Cancelled").
  - `bool matches(OrderListEntry e)` — `all` matches everything; the others match the
    corresponding `OrderListStatus`.

## Filtering & sorting (screen state)

`OrdersScreen` (`StatefulWidget`) holds:
- `OrdersTab _tab = OrdersTab.all`
- `String _query = ''`
- `bool _searchOpen = false`
- `OrdersSort _sort = OrdersSort.newest`
- `OrdersDateFilter _dateFilter = OrdersDateFilter.all`

New small enums in the model file:
- `enum OrdersSort { newest, highestEarning }` (`String get label`).
- `enum OrdersDateFilter { all, today }` (`String get label`; `today` keeps entries whose
  `dateGroup` starts with "Today").

Derivation (pure functions, unit-testable, top-level in the model file):
- `List<OrderListEntry> filterEntries({required List<OrderListEntry> all, required OrdersTab tab,
  required String query, required OrdersDateFilter dateFilter})` — applies tab, then a
  case-insensitive substring match of `query` against `restaurantName` or `id`, then the date
  filter.
- `List<OrderListEntry> sortEntries(List<OrderListEntry> entries, OrdersSort sort)` — `newest`
  keeps `mockList` order (already newest-first); `highestEarning` sorts by `amount` descending
  (stable).
- `Map<String, List<OrderListEntry>> groupByDate(List<OrderListEntry> entries)` — a
  `LinkedHashMap` preserving first-seen order, keyed by `dateGroup`.

## Screen structure

`Scaffold` (`AppColors.background`) → `SafeArea` → `ResponsiveFrame(maxWidth: 520)` → `Column`:
- `OrdersHeader(searchOpen, query, onToggleSearch, onQueryChanged, onOpenFilter)` — pinned
  (not scrolled): logo + "Delivery Partner" + Online pill on the first row; then a row with the
  "My Orders" title and two icon buttons (search toggle, filter). When `searchOpen`, an inline
  `SearchBarCustom` appears below the title row.
- `OrdersTabBar(current, onChanged)` — pinned, horizontally-scrollable underlined tabs.
- `Expanded` → the results area. The list is derived as a pipeline each build:
  `filterEntries(...)` → `sortEntries(..., _sort)` → `groupByDate(...)`.
  - If the filtered list is empty → `EmptyState(icon: LucideIcons.inbox, message: 'No orders here yet')`.
  - Else a `ListView` (`BouncingScrollPhysics`) of: for each date group, a
    `DateGroupHeader(label)` then its `OrderListCard`s; followed by `OrdersSupportBanner`
    and bottom padding.
- `AppBottomNav(currentIndex: 2)`.

Callbacks: `onToggleSearch` flips `_searchOpen` (clearing `_query` when closing);
`onQueryChanged` sets `_query`; `onOpenFilter` shows `OrderFilterSheet` and applies the result;
tab `onChanged` sets `_tab`. Card `onTap` calls a screen-level `_openDetails(entry)` that shows
a `SnackBar('Order details coming soon')` (stub).

## Widgets (`lib/features/orders/widgets/`)

- `orders_header.dart` — `OrdersHeader` as described. Online pill reuses the small
  dot+label+chevron pattern (local, like the Home greeting pill). Icon buttons are 44dp with
  `tooltip`s ("Search", "Filter").
- `orders_tab_bar.dart` — `OrdersTabBar({required OrdersTab current, required ValueChanged<OrdersTab> onChanged})`.
  A `SingleChildScrollView(horizontal)` `Row` of tab labels; the active tab is
  `AppColors.primary` bold with a 3dp underline bar, inactive is `textSecondary`.
- `date_group_header.dart` — `DateGroupHeader({required String label})`: calendar icon +
  label in `AppTypography.bodyMedium`.
- `order_list_card.dart` — `OrderListCard({required OrderListEntry entry, required VoidCallback onTap})`:
  - A `Row`: a left rail (fixed ~92dp) with the status word ("Upcoming"/"Completed"/"Cancelled"
    colored by status), the `timeLabel`, and a status icon (upcoming → `LucideIcons.history`
    tinted; completed → check in a soft circle; cancelled → `LucideIcons.x` in a red soft
    circle). A subtle vertical divider separates rail from content.
  - Content column: top row = "Order ID\n#id" (left) + `StatusChip` badge + amount
    (`rupeesPrecise`) + chevron; restaurant row (store icon in a red-ish circle, name + area);
    drop row (green pin, `dropAddress`); a "distanceKm km • timeAwayLabel" caption; and, when
    `status == upcoming`, a right-aligned outlined **View Details** button.
  - The card background tints faintly by status (upcoming → success-tinted, completed →
    surface, cancelled → error-tinted) to match the mockup's colored left edge.
  - Whole card is tappable (`InkWell`) → `onTap`; the View Details button also → `onTap`.
- `orders_support_banner.dart` — `OrdersSupportBanner({VoidCallback? onGetSupport})`:
  headphone icon + "Facing an issue with your order?" + "Get help from our support team." +
  outlined **Get Support** button.
- `order_filter_sheet.dart` — `OrderFilterSheet.show(context, {required OrdersSort sort,
  required OrdersDateFilter dateFilter})` → `Future<OrdersFilterResult?>`. A bottom sheet with
  a "Sort by" group (`FilterChipCustom` for each `OrdersSort`) and a "Date" group (each
  `OrdersDateFilter`), plus **Clear** (resets to newest/all) and **Apply** (pops the selection).
  `OrdersFilterResult { OrdersSort sort; OrdersDateFilter dateFilter; }` is a small local class.

## Badge → StatusChip mapping

- newOrder → label "New", `AppColors.warning` on `AppColors.warningBg`.
- delivered → label "Delivered", `AppColors.success` on `AppColors.successBg`.
- cancelled → label "Cancelled", `AppColors.error` on `AppColors.error.withValues(alpha: .12)`.

## Cross-cutting standards

- Touch targets ≥ 44dp; one clear primary affordance per card (the card tap).
- Money: `CurrencyFormatter.rupeesPrecise`. A ₹0.00 cancelled amount renders as "₹0.00".
- Colors: green = completed/success, amber = new/upcoming attention, red = cancelled, blue =
  info/actions.
- Accessibility: icon-only buttons get `tooltip`/`Semantics`; status conveyed by icon + text +
  color, never color alone; the tab bar exposes selected state semantically.
- No new packages. `lucide_icons`, `get`, `equatable` cover everything.
- Wrapped in `SafeArea` + `ResponsiveFrame(maxWidth: 520)`.

## Testing

Unit/widget tests in `frontend/test/`, mirroring `lib/`:

- Model: `OrdersTab.matches` classifies each status correctly; `filterEntries` narrows by tab,
  query (restaurant + id, case-insensitive), and date filter; `sortEntries` orders
  `highestEarning` by amount desc and leaves `newest` untouched; `groupByDate` preserves
  first-seen group order.
- `OrdersTabBar`: renders four labels; tapping one fires `onChanged` with the right tab.
- `OrderListCard`: renders order id, restaurant, badge label, amount; upcoming shows
  "View Details" and completed does not; tapping the card fires `onTap`.
- `OrderFilterSheet`: shows sort + date options; selecting Highest earning + Apply returns a
  result with `sort == highestEarning`.
- `OrdersScreen`: defaults to All with all groups; switching to Cancelled shows only the
  cancelled entry; opening search and typing "burger" narrows to Burger Point; a query with no
  matches shows the empty state; tapping the Home tab navigates to `/dashboard` (nav wiring).
