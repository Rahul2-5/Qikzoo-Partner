# Profile Screen — Design

## Context

Fourth and final tab of the Delivery Partner app's bottom navigation (Home, Earnings, and
Orders built first — see their specs dated 2026-07-13). The mockup shows a partner profile:
an identity card, a documents-verified banner, a wallet-balance card, an account/settings menu,
and a footer encouragement banner.

The `/profile` route already exists as a placeholder, and `AppBottomNav` routes tab index 3
there. The codebase has a thin Riverpod `PartnerProfileModel` (name/phone/vehicle/joined) and
`RatingModel`, plus empty `features/profile/` folders. Shared widgets available:
`CachedAvatar`, `ResponsiveFrame`, `ConfirmationDialog`, `AppBottomNav`. Several menu
destinations already have placeholder routes: `bankDetails` (`/bank-details`),
`verificationStatus` (`/verification-status`), `wallet` (`/wallet`), `support` (`/support`),
`notifications` (`/notifications`), `settings` (`/settings`), `documentUpload` (`/documents`),
`welcome` (`/welcome`).

Decisions from brainstorming:

- **State**: pure mock, matching the other tabs. `ProfileScreen` is a `StatelessWidget` (no
  local interactive state; menu taps navigate or show a snackbar). Log Out uses an async dialog.
- **Model**: a dedicated lightweight `ProfileSummary` mock model rather than overloading the
  Riverpod `PartnerProfileModel`.
- **Navigation**: rows with a sensible existing route navigate via `Get.toNamed`; rows without
  one show a "coming soon" snackbar (so users aren't dropped into registration forms).
- **Log Out**: the existing `ConfirmationDialog`; confirming clears the stack with
  `Get.offAllNamed(AppRoutes.welcome)`.
- **Fidelity**: keep the Qikzoo brand and existing design tokens; improve hierarchy, spacing,
  and accessibility freely.

## Scope

In scope: the Profile screen, its mock model, its widgets, and registering the `/profile`
route to the real screen. Out of scope: real backend, and building any of the destination
screens (they remain existing placeholder routes); this screen only navigates to them.

## Route mapping

- Register `GetPage(name: AppRoutes.orders...)`-style entry:
  `GetPage(name: AppRoutes.profile, page: () => const ProfileScreen())`, replacing the
  placeholder. `AppRoutes.profile` and `AppBottomNav` index 3 already exist — no nav change.
- Navigation targets (via `Get.toNamed`, except Log Out):
  - Notification bell → `AppRoutes.notifications`.
  - Documents Verified banner → `AppRoutes.verificationStatus`.
  - Withdraw button → `AppRoutes.wallet`.
  - Menu "Bank Details" → `AppRoutes.bankDetails`.
  - Menu "Documents" → `AppRoutes.documentUpload`.
  - Menu "Help & Support" → `AppRoutes.support`.
  - Menu "Settings" → `AppRoutes.settings`.
  - Menu "Log Out" → `ConfirmationDialog` → `Get.offAllNamed(AppRoutes.welcome)`.
- Snackbar-stubbed ("coming soon"): View Stats button, and menu rows "Personal Information",
  "Vehicle Details", "Incentives & Offers".

## Mock data model (`lib/models/profile/profile_summary.dart`)

`ProfileSummary` (Equatable):
- `String name` ("Rahul Verma")
- `String partnerId` ("ZP12345678")
- `String? photoUrl` (null → `CachedAvatar` shows its user-icon fallback)
- `double ratingAverage` (4.8)
- `String deliveriesLabel` ("250+ Deliveries")
- `bool documentsVerified` (true)
- `double walletBalance` (2345.50)
- `String bankName` ("HDFC Bank")
- `String maskedAccount` ("4321")
- `String nextPayoutDate` ("15 May 2025")
- `int notificationCount` (3)
- `factory ProfileSummary.mock()` returns the values above.

## Screen structure

`ProfileScreen` (`StatelessWidget`). `Scaffold` (`AppColors.background`) → `SafeArea` →
`ResponsiveFrame(maxWidth: 520)` → `Column`:
- `Expanded` → `SingleChildScrollView` (`BouncingScrollPhysics`) containing, with `AppSpacing.md`
  gaps:
  1. `ProfileHeader(notificationCount, onNotifications)` — logo + "Delivery Partner", Online
     pill, notification bell with a small count badge.
  2. `ProfileIdentityCard(summary, onViewStats)` — `CachedAvatar`, name, "Delivery Partner ID:
     {partnerId}", a rating + deliveries row (star icon + "4.8" + divider + "{deliveriesLabel}"),
     and an outlined **View Stats** button.
  3. `VerificationBanner(verified, onTap)` — green shield, "Documents Verified" title +
     "All your documents are verified" subtitle, chevron; tappable. (When `verified` is false it
     shows amber "Verification pending" copy — mock always passes true, but the widget handles
     both so it's not brittle.)
  4. `WalletBalanceCard(summary, onWithdraw)` — "Wallet Balance" label, big
     `rupeesPrecise(walletBalance)`, "{bankName} ····{maskedAccount}" and "Next payout:
     {nextPayoutDate}", and a gradient **Withdraw** button (reuses `PrimaryCtaButton`,
     `fullWidth: false`).
  5. A menu card: a `Column` of `ProfileMenuTile`s separated by dividers, built from a
     data list (below).
  6. `ProfileFooterBanner()` — soft card: "Keep delivering, keep earning!" + a rider motif
     (icon-based, no asset) + "Stay safe ♥".
  7. bottom padding.
- `AppBottomNav(currentIndex: 3)`.

### Menu data

The screen builds the menu from a private list of records
`({IconData icon, String title, String subtitle, VoidCallback onTap, bool destructive})`:

1. Personal Information — "Update your personal details" — snackbar stub.
2. Bank Details — "Manage your bank account" — `Get.toNamed(bankDetails)`.
3. Vehicle Details — "Manage your vehicle information" — snackbar stub.
4. Documents — "View and manage your documents" — `Get.toNamed(documentUpload)`.
5. Incentives & Offers — "View your ongoing offers" — snackbar stub.
6. Help & Support — "Get help and raise issues" — `Get.toNamed(support)`.
7. Settings — "App settings and preferences" — `Get.toNamed(settings)`.
8. Log Out — "Log out from your account" — destructive; `ConfirmationDialog` → `offAllNamed(welcome)`.

## Widgets (`lib/features/profile/widgets/`)

- `profile_header.dart` — `ProfileHeader({required int notificationCount, required VoidCallback
  onNotifications})`. Online pill reuses the dot+label+chevron pattern. The bell is a 44dp icon
  button with a small overlaid count badge (`Stack` + `Positioned`), `tooltip: 'Notifications'`;
  badge hidden when count is 0.
- `profile_identity_card.dart` — `ProfileIdentityCard({required ProfileSummary summary, required
  VoidCallback onViewStats})`. Surface card with a top `Row`: `CachedAvatar` (radius 32) on the
  left, an `Expanded` column (name `AppTypography.h2`, ID caption, then a rating row: star
  `AppColors.accent` + rating text + a thin vertical divider + deliveries label) in the middle,
  and a compact outlined **View Stats** button on the right. The `Expanded` middle absorbs width
  so the row never overflows on narrow screens.
- `verification_banner.dart` — `VerificationBanner({required bool verified, required VoidCallback
  onTap})`. `InkWell` card tinted `successBg` (verified) or `warningBg` (pending); shield icon;
  title + subtitle; trailing chevron. Semantic label reflects state.
- `wallet_balance_card.dart` — `WalletBalanceCard({required ProfileSummary summary, required
  VoidCallback onWithdraw})`. A `primarySoft`/gradient card: left column (label, big amount,
  bank + payout captions), right the Withdraw CTA. Uses `CurrencyFormatter.rupeesPrecise`.
- `profile_menu_tile.dart` — `ProfileMenuTile({required IconData icon, required String title,
  required String subtitle, required VoidCallback onTap, bool destructive = false})`. `InkWell`
  row: tinted icon circle (`primarySoft`/`primary`, or `error` tint when destructive), title +
  subtitle column, trailing chevron (hidden when destructive). ≥56dp tall.
- `profile_footer_banner.dart` — `ProfileFooterBanner()`. Soft gradient card with a scooter/rider
  icon motif, heading, encouragement line, and a "Stay safe ♥" accent. Purely decorative.

## Cross-cutting standards

- Touch targets ≥ 48dp; menu rows ≥ 56dp. Icon-only buttons (bell) get `tooltip`/`Semantics`.
- Money via `CurrencyFormatter.rupeesPrecise` (₹2,345.50 — grouping already added in the
  Earnings work).
- Colors: green = verified/success, blue = primary/actions, red = destructive (Log Out),
  amber = pending state. Status never by color alone (icon + text).
- No continuous animations; no controllers.
- No new packages. `lucide_icons`, `get`, `equatable`, `cached_network_image` (already used by
  `CachedAvatar`) cover everything.
- Wrapped in `SafeArea` + `ResponsiveFrame(maxWidth: 520)`.

## Testing

Unit/widget tests in `frontend/test/`, mirroring `lib/`:

- Model: `ProfileSummary.mock()` returns the documented name, partnerId, rating, wallet balance,
  and notificationCount.
- `ProfileIdentityCard`: renders name, "Delivery Partner ID: ZP12345678", "4.8", the deliveries
  label; tapping View Stats fires `onViewStats`.
- `WalletBalanceCard`: shows "₹2,345.50", the bank + masked account, the payout date; tapping
  Withdraw fires `onWithdraw`.
- `VerificationBanner`: verified state shows "Documents Verified"; tap fires `onTap`.
- `ProfileMenuTile`: renders title + subtitle; tap fires `onTap`; destructive variant hides the
  chevron.
- `ProfileHeader`: shows the notification badge count; tapping the bell fires `onNotifications`.
- `ProfileScreen`: renders the partner name and all eight menu titles; tapping "Settings"
  navigates to `/settings`; tapping "Log Out" opens the dialog and confirming navigates to
  `/welcome`; tapping the Home tab navigates to `/dashboard`.
