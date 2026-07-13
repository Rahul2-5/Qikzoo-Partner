# Home Screen & Active Order Flow — Design

## Context

The Home experience currently lives entirely in
`frontend/lib/features/dashboard/screens/dashboard_screen.dart` (~57KB): one `StatefulWidget`
holding the online/offline state, a mock `OrderModel`, a `Timer` that simulates an incoming
order, and ~30 private widget classes covering every phase of the order lifecycle
(`OrderStatus`: waitingForOrders → incomingRequest → accepted → navigatingToRestaurant →
arrivedAtRestaurant → pickupConfirmed → navigatingToCustomer → arrivedAtCustomer →
deliveryConfirmed → completed). The mockups for Home / New Order / Picked Up / Delivered are
rough direction, not final layouts; this design upgrades the UX to production level and
decomposes the monolith.

Decisions made during brainstorming:

- **Scope**: Home idle states + the full active-order flow, refactored into separate screens
  and feature widgets. Earnings / Orders / Profile tabs are out of scope (later phases).
- **Data**: pure mock, UI-only. `setState` + `Timer` simulation stays; no providers,
  repositories, or API calls. The shell owns all state and passes callbacks down.
- **Maps**: stylized `CustomPainter` placeholder (markers + dashed route on a decorative
  grid), no map SDK.
- **Incoming order**: full-screen takeover with a 30s countdown (Swiggy/Zomato pattern),
  not an inline card.
- **Fidelity**: keep the Qikzoo brand language (blue/green gradients, light airy cards,
  existing `AppColors`/`AppTypography`/`AppShadows` tokens) but improve hierarchy, touch
  targets, and accessibility freely where the mockups fall short.

## File structure

Keep the `features/dashboard/` folder and the `/dashboard` route (no route churn). Replace
the monolith with:

```
features/dashboard/
  screens/
    dashboard_screen.dart        # Shell: owns state machine + mock order, hosts bottom nav,
                                 # switches between the views below (~150 lines)
    home_idle_view.dart          # States A & B (offline / online-waiting) — a view widget,
                                 # not a routed screen
    incoming_order_screen.dart   # State C — full-screen takeover (pushed via Navigator)
    active_order_view.dart       # State D — restaurant + customer phases, phase-driven
    order_delivered_view.dart    # State E — success summary
  widgets/
    greeting_header.dart         # Logo, greeting, online status pill, Help button
    todays_earnings_card.dart    # Gradient wallet card ("Today's Earnings ₹920.50")
    order_progress_tracker.dart  # Restaurant Pickup → On the way → Customer Drop stepper
    order_details_card.dart     # Restaurant row + Order ID (copy) + items + customer note
    customer_location_card.dart  # Address + Navigate button + MapPreview
    map_preview.dart             # CustomPainter stylized map, start/end markers, route line
    earnings_strip.dart          # "Estimated Earning ₹38.50 · View detail"
    accept_countdown_ring.dart   # Animated circular 30s timer
    swipe_action_button.dart     # Swipe-to-confirm control for critical actions
    waiting_for_orders_card.dart # Animated "Finding orders near you…" pulse state
    offline_hero_card.dart       # Offline hero with dominant Go Online CTA
    delivery_success_card.dart   # Green success banner with earned amount
    rating_selector.dart         # 5-star "How was this delivery experience?"
    incentive_progress_card.dart # "12/20 deliveries → ₹150 extra" progress
    stat_tile_row.dart           # Deliveries today / hours online / rating mini-stats
```

Reused shared widgets: `FloatingBottomNav`, `OnlineOfflineSwitch`, `ConfirmationDialog`,
`PrimaryCtaButton`, `ResponsiveFrame`, `StatusChip`, `CountdownTimer` (evaluate; the ring
is new), `EarningsBreakdownWidget`, `RatingStars` (reuse inside `rating_selector` if it fits).

The old private classes in `dashboard_screen.dart` are deleted as their replacements land;
no dead code remains at the end.

## State model

The shell (`DashboardScreen`) keeps today's approach, cleaned up:

- `bool online`, `OrderModel? currentOrder`, `OrderStatus status`.
- `Timer` simulates an incoming order 2s after going online (unchanged).
- Incoming order pushes `IncomingOrderScreen` as a full-screen route
  (`Navigator.push` with a slide-up `PageRouteBuilder`); it returns `accepted: bool`
  (or times out → auto-reject). Accept → shell switches body to `ActiveOrderView`.
- `advance()` walks the same `OrderStatus` map as today. `deliveryConfirmed` shows
  `OrderDeliveredView`; its Continue resets to online-waiting.
- Going offline mid-order is blocked with an explanatory dialog.
- Bottom nav is visible only in states A/B/E; hidden during incoming + active order.

## Screen states

### A. Home — Offline (default)

`GreetingHeader` ("Hi, Rahul 👋" / "Ready to deliver?"), `TodaysEarningsCard`,
`OfflineHeroCard` (illustration-style zone, "You're offline" + explanatory line + dominant
**Go Online** `PrimaryCtaButton`), `StatTileRow`. Go Online confirms via
`ConfirmationDialog` (existing behavior), then transitions to B.

### B. Home — Online, waiting

Same skeleton; hero swaps to `WaitingForOrdersCard`: an animated radar/pulse
(`AnimationController` with 2 expanding fading circles around a scooter icon), "Finding
orders near you…" text. Header status pill shows Online (green dot). A secondary
(outlined) **Go Offline** button sits below the fold-safe area; confirmation dialog before
going offline.

### C. Incoming Order — full-screen takeover

Pushed as a route with slide-up transition; bottom nav not present; back gesture = reject
(with the same auto-reject path).

Layout top-to-bottom:
- `AcceptCountdownRing` (56–64dp) top-center with seconds remaining; ring color
  `AppColors.success` → warning amber under 10s → error red under 5s;
  `HapticFeedback.mediumImpact` at 10s and 5s. Expiry pops the route with rejected result
  and shows an "Order missed" snackbar on Home.
- "New Order" title + `StatusChip` ("New").
- **Earnings first**: large ₹38.50 with "Estimated earning" label (primary decision factor).
- Pickup row (restaurant icon, name, area, distance-to-restaurant) and Drop row (pin icon,
  address, trip distance) joined by a vertical dashed connector.
- Compact order meta: item count ("3 items"), payment type placeholder.
- Bottom, sticky: full-width **Accept Order** `PrimaryCtaButton` (≥56dp tall) above a
  text-style **Reject** button (destructive red text, not equal visual weight — rejecting
  should be possible but not accidental).

### D. Active Order — one view, two phases

Phase derived from `OrderStatus`: restaurant phase (accepted / navigatingToRestaurant /
arrivedAtRestaurant) vs customer phase (pickupConfirmed / navigatingToCustomer /
arrivedAtCustomer). Single `ActiveOrderView` re-renders per phase; no separate routes.

- Header: back-less title ("Pick up order" / "Order picked up") + subtitle + Help outlined
  button (existing header pattern).
- `OrderProgressTracker` pinned under the header; segments animate fill on phase change
  (250ms `AnimatedContainer`/`TweenAnimationBuilder`); completed nodes get a check badge.
- Contextual status banner: restaurant phase → "Pick up in 3 mins" + `CountdownTimer`
  chip + Call button; customer phase → green "Order picked up at 10:25 AM" card + Call.
- `CustomerLocationCard` (or restaurant location in restaurant phase): address, Navigate
  button (stub `onPressed`, ready for url_launcher later), `MapPreview` with distance/ETA
  strip ("4.2 km away · 12 mins delivery · Light traffic").
- `OrderDetailsCard`: restaurant row, Order ID + Copy (uses `Clipboard.setData` + snackbar
  "Order ID copied"), expandable Order Items, expandable Customer Note
  (`AnimatedCrossFade` or `ExpansionTile` styled to match cards).
- `EarningsStrip`.
- Sticky bottom action area (always above the fold, never inside the scroll):
  - accepted → **Navigate to Restaurant** (tap)
  - navigatingToRestaurant → **Reached Restaurant** (tap)
  - arrivedAtRestaurant → **Confirm Pickup** (`SwipeActionButton`)
  - pickupConfirmed/navigatingToCustomer → **Reached Customer** (tap)
  - arrivedAtCustomer → **Confirm Delivery** (`SwipeActionButton`)
  - Secondary: Help & Support outlined button beside tap CTAs; swipe CTAs get full width
    with Help as a small icon button.

`SwipeActionButton`: rounded track with gradient fill following the thumb
(`GestureDetector` + `AnimatedBuilder`); release before 85% springs back; crossing 85%
completes with `HapticFeedback.lightImpact` and fires `onConfirmed`. Prevents accidental
confirmation of the two money-relevant actions while on a vehicle.

### E. Delivered

- Header "Order delivered / Great job! 🎉" with completed `OrderProgressTracker` (all
  checks).
- `DeliverySuccessCard`: green gradient, check badge, "Order delivered successfully!",
  timestamp, "You have earned ₹38.50".
- Delivery summary rows (order ID + copy, restaurant, customer location, total distance).
- `RatingSelector` (5 labelled stars, local state only, selecting fills stars + shows
  a "Thanks for the feedback" microcopy).
- `EarningsBreakdownWidget` (delivery fee / distance pay / incentive / total — reuse shared
  widget).
- `IncentiveProgressCard` (12/20 progress bar + "8 deliveries away from ₹150 extra").
- Sticky **Continue** `PrimaryCtaButton` → resets shell to state B (online, waiting).
  Bottom nav visible again on this state.

## Cross-cutting production standards

- Touch targets ≥ 48dp; primary CTAs ≥ 56dp tall; exactly one primary action per state.
- Motion: 250–300ms `AnimatedSwitcher` (fade + slight slide) between shell states;
  countdown ring, radar pulse, tracker fill, and swipe thumb are the only continuous
  animations. All controllers disposed; no animation runs when its view is off-screen.
- Color semantics: green = go/earnings/success, blue = info/navigation, amber = time
  pressure, red = destructive (reject / offline / expiry).
- Accessibility: `Semantics` labels on icon-only buttons (Call, Copy, Help, Navigate),
  text contrast ≥ 4.5:1 against card surfaces, star rating exposes semantic labels
  ("Rate Good, 4 of 5"), state never conveyed by color alone (icons/text accompany).
- All screens wrapped in `SafeArea` + `ResponsiveFrame(maxWidth: 520)` (existing pattern).
- No new packages. `lucide_icons`, `get`, `equatable` already in the project cover needs.

## Edge handling (mock scope)

- Countdown expiry → auto-reject, "Order missed" snackbar, back to state B.
- Go Offline while an order is active → blocked `ConfirmationDialog`-style info dialog
  ("Finish your current delivery first").
- Empty customer note → note section hidden entirely (no empty expandable).
- Rapid double-taps on CTAs guarded (button disables while transition runs).

## Testing

Widget tests in `frontend/test/` following existing conventions:

- Per-widget: `OrderProgressTracker` (phase rendering), `AcceptCountdownRing` (color
  thresholds via pumped durations), `SwipeActionButton` (incomplete drag springs back,
  full drag fires `onConfirmed`), `OrderDetailsCard` (copy fires clipboard + snackbar,
  expandables toggle), `RatingSelector` (tap selects), `IncomingOrderScreen` (accept pops
  true, reject pops false, expiry pops false).
- Flow test: pump `DashboardScreen`, walk offline → go online → incoming appears (fake
  timer) → accept → advance through all statuses → delivered → continue → back to
  waiting. Asserts the correct CTA label at each step.
