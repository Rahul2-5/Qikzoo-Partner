# Delivery Partner App — Frontend Setup Design

Date: 2026-07-09
Scope: `frontend/` only. No backend, no Firebase, no real APIs, no local database. Everything is designed so a real REST backend can be plugged in later with minimal rework.

## Context

New Flutter project "Delivery Partner App" (Qikzoo Partner), built inside a monorepo under `frontend/`. A supporting document (`Delivery_Partner_App_Documentation.docx`, repo root) provided additional product context: full onboarding journey, order lifecycle, dashboard requirements, and differentiation ideas (itemized earnings breakdown, fatigue nudges, etc.) — folded into this design where relevant. Screens will be built one at a time in later sessions, each rebuilt against the locked design system below using reference screenshots for layout/structure only, never visual style.

## Decisions Locked In (via clarifying questions)

- **Feature layering: type-first**, not feature-first. Top-level `models/`, `providers/`, `services/`, `repositories/` each split into per-domain subfolders; `features/<name>/` holds only `screens/` and `widgets/`. (Superseded an earlier feature-first proposal after the user provided a reference structure from another project.)
- **No `controllers/` folder.** `TextEditingController`/`ScrollController`/`PageController` instances are created and disposed locally inside the widgets that use them. Keeps the Riverpod-only-state / GetX-only-navigation rule unambiguous.
- **App identity:** package `com.qikzoo.deliverypartner`, pubspec name `delivery_partner_app`, display name "Qikzoo Partner".
- **Test and localization scaffolding deferred** — not included in this initial setup pass, added when actually needed.
- **Riverpod: hand-written, no codegen.** No `riverpod_generator`/`build_runner`.
- **Fonts/icons:** `google_fonts` package (Manrope for headings, Inter for body/data) + `lucide_icons` package for outline icons. No bundled font files.
- **Platforms:** Android + iOS only. No web/desktop targets.

## Tech Stack

- Flutter + Dart, SDK `>=3.4.0 <4.0.0`
- Navigation: GetX — named routes only, never state
- State: Riverpod (`flutter_riverpod`) — strictly, hand-written providers/notifiers, no codegen
- Architecture: Clean-ish, type-first, feature-scoped screens/widgets
- Icons: `lucide_icons`, outline/flat style only
- Spacing: strict 8px grid via `AppSpacing` tokens

## Folder Structure

```
frontend/
├── lib/
│   ├── core/
│   │   ├── theme/            # app_theme, app_colors, app_typography, app_spacing, app_radius, app_shadows
│   │   ├── constants/
│   │   ├── routes/           # app_routes.dart, app_pages.dart
│   │   ├── di/
│   │   ├── network/          # api_client stub, interceptors (unused placeholder)
│   │   ├── error/             # failure.dart, exceptions.dart, result.dart
│   │   ├── utils/, validators/, extensions/, helpers/
│   │   └── assets/            # app_assets.dart typed asset paths
│   │
│   ├── models/
│   │   ├── authentication/, partner_registration/, document_verification/, bank_details/,
│   │   │   verification_status/, training/, agreement/, approval/, dashboard/, orders/,
│   │   │   wallet/, support/, profile/, notifications/, settings/
│   │
│   ├── providers/
│   │   └── <same 15 domains>  # UI-state and domain-state providers kept in separate files per domain
│   │
│   ├── services/
│   │   └── <same 15 domains>  # mock async services simulating latency/errors
│   │
│   ├── repositories/
│   │   └── <same 15 domains>  # abstract repository interface + mock implementation together
│   │
│   ├── shared/
│   │   └── widgets/
│   │       ├── buttons/, cards/, inputs/, chips/, navigation/, toggles/, dialogs/, misc/
│   │
│   ├── features/
│   │   ├── splash/{screens,widgets}
│   │   ├── onboarding_welcome/{screens,widgets}
│   │   ├── authentication/{screens,widgets}
│   │   ├── partner_registration/{screens,widgets}
│   │   ├── document_verification/{screens,widgets}
│   │   ├── bank_details/{screens,widgets}
│   │   ├── verification_status/{screens,widgets}
│   │   ├── training/{screens,widgets}
│   │   ├── agreement/{screens,widgets}
│   │   ├── approval/{screens,widgets}
│   │   ├── dashboard/{screens,widgets}
│   │   ├── orders/{screens,widgets}
│   │   ├── wallet/{screens,widgets}
│   │   ├── support/{screens,widgets}
│   │   ├── profile/{screens,widgets}
│   │   ├── notifications/{screens,widgets}
│   │   └── settings/{screens,widgets}
│   │
│   ├── app.dart
│   └── main.dart
│
├── assets/
│   ├── images/, icons/, illustrations/, animations/, fonts/ (empty — google_fonts used instead)
│
├── test/       # empty for now
└── pubspec.yaml
```

**Dependency rule:** `features/*/screens` and `features/*/widgets` are the only things that import from `providers/`, `models/`, `repositories/`, `services/`, and only their own domain's slice. `shared/widgets` never imports from `models/`, `providers/`, or `features/` — stays generic (typed props in, callbacks out).

## pubspec.yaml Dependencies

```yaml
name: delivery_partner_app
description: Qikzoo Delivery Partner — frontend
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  get: ^4.6.6
  lucide_icons: ^0.257.0
  google_fonts: ^6.2.1
  shimmer: ^3.0.0
  cached_network_image: ^3.3.1
  lottie: ^3.1.2
  pin_code_fields: ^8.0.1
  flutter_svg: ^2.0.10+1
  intl: ^0.19.0
  equatable: ^2.0.5
  flutter_animate: ^4.5.0
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

- No `dio`/`http` — `core/network/` gets a hand-written `ApiClient` stub only.
- No `freezed`/`json_serializable` — hand-written `fromJson`/`toJson`/`copyWith`, matching the no-codegen Riverpod decision.
- `equatable` for value equality on models/state (Riverpod rebuild correctness).
- `flutter_animate` for "smooth, purposeful animations" called out in the visual-language spec.

## Theme Token Architecture

Five token files + one assembler in `core/theme/`:

- **`app_colors.dart`** — Primary `#1B2559`, Secondary `#2F6FED`, Accent `#FFB800`, Success `#16A34A`, Warning `#E4572E`, Background `#F7F8FA`, Surface `#FFFFFF`, text primary `#111827` / secondary `#6B7280`. Tinted `*Bg` variants (12–14% opacity) derived for status-chip backgrounds.
- **`app_spacing.dart`** — named 8px-grid steps: `xs=4, sm=8, md=16, lg=24, xl=32, xxl=40`. No raw numbers at call sites.
- **`app_radius.dart`** — `card=18, button=15, chip=999 (pill), sheet=24`.
- **`app_shadows.dart`** — `AppShadows.card` (soft dual-tone neumorphic shadow) and `AppShadows.glass(opacity)` (reserved for the 3 approved glassmorphism touch-points: floating bottom nav, modal sheets/dialogs, Online/Offline toggle — not the whole UI).
- **`app_typography.dart`** — Manrope (via `google_fonts`) for headings, Inter for body/data. `numericLg`/`numericMd` variants use `FontFeature.tabularFigures()` for earnings/counts.
- **`app_theme.dart`** — assembles all tokens into one `ThemeData` (light only, no dark mode requested), consumed once in `app.dart`.

Every widget reads `AppColors.x` / `AppSpacing.x` / etc. directly — never `Theme.of(context).colorScheme.x`, never a raw hex or magic number inline.

## Riverpod Conventions

Per domain, UI state and domain state are physically separate files:

- **UI state** (ephemeral, screen-local: form inputs, toggles, selected tab) → plain `StateProvider` or small `Notifier`.
- **Domain state** (business data backed by a mock repository) → `AsyncNotifierProvider` wrapping repository calls, exposing `AsyncValue<T>` for built-in loading/error/data handling.
- **Repository providers** live beside the repository: `abstract class XRepository { ... }`, `final xRepositoryProvider = Provider<XRepository>((ref) => MockXRepository());`, and `class MockXRepository implements XRepository { ... }` with simulated latency (`Future.delayed`) and canned data.
- The backend swap point later is exactly one line — the `Provider` body inside `xRepositoryProvider` — with zero changes to providers, screens, or widgets.

## GetX Routing Conventions

- `core/routes/app_routes.dart` — route name string constants only, no logic.
- `core/routes/app_pages.dart` — the `GetPage` table; route-specific transitions live here, not scattered across widgets.
- `app.dart` wires `ProviderScope` (Riverpod) around `GetMaterialApp` (GetX) at the single root, `initialRoute: AppRoutes.splash`.
- Navigation anywhere in the app uses `Get.toNamed(...)`/`Get.offAllNamed(...)` — never `Navigator.push`, never a GetX controller holding state.

## Shared Widget Stubs

Every shared widget takes typed props + callbacks only, no imports from `models/`, `providers/`, or `features/`:

- **buttons/** — primary_cta_button, secondary_button, outlined_button_custom, icon_button_custom, glass_button
- **cards/** — stat_card, order_card, document_upload_card, info_card
- **inputs/** — otp_field, app_text_field, app_dropdown, search_bar_custom
- **chips/** — status_chip (enum-driven, not string-matched), filter_chip_custom
- **navigation/** — floating_bottom_nav (max 5 items, glass-accented), top_app_bar_custom, step_progress_indicator, section_header
- **toggles/** — online_offline_switch (glass-accented)
- **dialogs/** — loading_dialog, confirmation_dialog, success_dialog, error_dialog
- **misc/** — empty_state, loading_skeleton, error_widget_custom, countdown_timer, earnings_breakdown_widget (base + distance + surge + tip itemization), rating_stars, cached_avatar

Each ships as a working stub — real widget class, typed constructor params, theme-token styling, plausible mock content — not a TODO placeholder, so screens can consume them immediately.

## UI Implementation Roadmap

Dependency-ordered: 1. Splash → 2. Onboarding Welcome → 3. Authentication (mobile entry + OTP) → 4. Partner Registration (personal info → vehicle selection → delivery zone) → 5. Document Verification → 6. Bank Details → 7. Verification Status → 8. Training → 9. Agreement → 10. Approval → 11. Dashboard (shell + bottom nav — everything after is a tab inside it) → 12. Orders → 13. Wallet → 14. Profile → 15. Support → 16. Notifications → 17. Settings.

## Out of Scope (this pass)

- Real screens (built one at a time in later sessions against reference screenshots)
- Test scaffolding, localization/`intl` l10n wiring
- Any backend/API/Firebase/local-db integration
- Dark mode
