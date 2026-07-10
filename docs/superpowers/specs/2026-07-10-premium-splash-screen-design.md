# Premium Splash Screen — Design

## Goal
Replace the current static splash (flat gradient, logo in a card, app name, spinner, hard 2s cut) with a production-level, premium-feel splash comparable to Swiggy/Zomato — using code-driven animation only, no new assets or dependencies.

## Constraints
- No Lottie asset exists (`assets/animations/` is empty) — animation must be built with `flutter_animate` (already in `pubspec.yaml`) and plain Flutter widgets.
- Must reuse existing design tokens: `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`. No new colors/fonts introduced.
- Must still navigate to `AppRoutes.welcome` via `Get.offAllNamed` after the sequence.
- No new packages added to `pubspec.yaml`.

## Sequence (~2.5s total)

| Time | Element | Motion |
|---|---|---|
| 0ms | Background | Static gradient `AppColors.primary → Color(0xFF0E7A63)` (unchanged), plus a radial glow layer centered behind the logo that pulses continuously (opacity/scale breathing loop, `repeat: true`) starting immediately. |
| 100–700ms | Logo card | Scale 0.4 → 1.0 with `Curves.elasticOut`, combined with fade-in (`.scale().fadeIn()`). |
| 500–900ms | App name | Fade-in + slide up 16px → 0, via `flutter_animate` `.fadeIn(delay: ...).slideY(begin: ...)`. |
| 800–1200ms | Tagline "Delivering Opportunities" | Fade-in + slide up, smaller/muted white text (`AppTypography.caption`-based, white with reduced opacity), appears beneath app name. |
| 1200ms+ | Loading indicator | Three pulsing dots (staggered fade/scale loop) replace the current `CircularProgressIndicator`. Fades in once tagline lands. |
| 2500ms | Exit | Whole content column fades + scales down slightly (`AnimatedOpacity`/`flutter_animate` reverse), then `Get.offAllNamed(AppRoutes.welcome)` fires — avoids an abrupt cut. |

## Components

1. **`SplashScreen` (StatefulWidget/ConsumerStatefulWidget, existing file)**
   - Keeps existing `Scaffold` + gradient `DecoratedBox` structure.
   - Wraps content in an `AnimatedOpacity` (or `flutter_animate` fade) driven by a bool `_exiting` flag, flipped ~300ms before navigation to produce the fade/scale-out.
   - Timer changes from a flat 2s delay to: wait for sequence to finish (~2.2s) → trigger exit animation (~300ms) → navigate (~2.5s total).

2. **Radial glow layer**
   - A `Container`/`DecoratedBox` with `RadialGradient` (soft white/teal glow fading to transparent), sized larger than the logo card, positioned behind it via `Stack`.
   - Animated with `flutter_animate`'s `.animate(onPlay: (c) => c.repeat(reverse: true))` on scale/opacity for a breathing pulse (~1.5–2s loop).

3. **Logo card** — existing white rounded `Container` with `logo.png`, now wrapped with `.animate().scale(curve: Curves.elasticOut).fadeIn()`.

4. **App name text** — existing `Text` widget, wrapped with `.animate(delay: ...).fadeIn().slideY(...)`.

5. **Tagline text** — new `Text` widget, "Delivering Opportunities", styled off `AppTypography.caption` with white/reduced-opacity color, wrapped with `.animate(delay: ...).fadeIn().slideY(...)`.

6. **Pulsing dots indicator** — new small stateless widget (private class or inline `Row`) of 3 circles (`Container` with `BoxShape.circle`, white translucent), each animated with staggered `.animate(delay: i * 150ms, onPlay: (c) => c.repeat())` scale/opacity loop. Replaces `CircularProgressIndicator`.

## Error handling / edge cases
- If `logo.png` fails to load, existing behavior (broken image icon) is unchanged — out of scope.
- Widget must guard `if (mounted)` before navigating, as today.
- Animation timing is all local `Duration` constants — no dependency on async work completing, so no risk of navigating before assets are ready (image is bundled).

## Testing
- Manual verification: run app, observe splash renders logo pop + glow pulse + name + tagline + dots, then fades out into onboarding welcome screen at ~2.5s, no jank/overflow.
- No new automated test required (splash screens are typically excluded from widget/golden tests in this repo — confirm no existing splash test exists before skipping).
