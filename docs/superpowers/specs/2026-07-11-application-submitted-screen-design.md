# Application Submitted Screen — Design

## Context

Final screen of the partner registration flow, shown after the last data-entry step
(Selfie Verification, `AppRoutes.selfieVerification`) confirms submission. It is a static
confirmation screen with no provider/state — purely presentational, mirroring the shell used
by `DocumentUploadScreen` and `SelfieVerificationScreen`.

## Scope

- Add `ApplicationSubmittedScreen` at new route `AppRoutes.applicationSubmitted =
  '/registration/application-submitted'`.
- Wire `SelfieVerificationScreen`'s "Continue" target (currently `AppRoutes.bankDetails`) to
  `AppRoutes.applicationSubmitted` instead, since this screen is the terminal step of the
  6-step registration flow shown in the mockup.
- "Go to Home" button navigates with `Get.offAllNamed(AppRoutes.dashboard)`, clearing the
  registration stack so back navigation can't return into the submitted/registration screens.
- Out of scope: no backend submission call, no new document/model types, no changes to
  `StepProgressIndicator` (this screen doesn't use it — see below).

## Screen structure

`ApplicationSubmittedScreen` (`StatelessWidget`), same shell as other registration screens:

`Scaffold` (`AppColors.background`) → `SafeArea` → `ResponsiveFrame(maxWidth: 520)` →
- Back arrow (`IconButtonCustom`, `Get.back()`).
- Gradient headline "Application Submitted" (same `Text.rich` + `ctaGradient` shader pattern
  as other screens — "Application " in `textPrimary`, "Submitted" gradient-filled).
- Centered illustration (new widget `SubmittedIllustration` in
  `lib/features/partner_registration/widgets/`): built from icons/containers, no image asset
  (project has none for this):
  - A rounded-rect "clipboard" `Container` (`AppColors.surface` fill, `AppColors.secondary`
    border, `AppRadius.card`) containing 5 short horizontal bar placeholders, each preceded
    by a small green check circle (`LucideIcons.check` on `AppColors.successBg`), plus a
    small dark rectangle "clip" at the top center.
  - A large green circle badge (`AppColors.success` fill) with a white `LucideIcons.check`,
    positioned bottom-right of the clipboard via `Stack`/`Positioned`.
  - 6 small scattered accents around the clipboard (`Positioned` `Icon`s using
    `LucideIcons.sparkle` and small filled `Container` dots), colored from
    `AppColors.secondary`, `AppColors.accent`, `AppColors.warning` for variety, matching the
    mockup's confetti-like dots/sparkles.
- Body text: "Your application has been submitted **successfully**!" as a centered
  `Text.rich` (gradient shader on "successfully" only, same pattern as the headline),
  followed by secondary-colored line "We will verify your details and get back to you soon."
- "What's next?" card: `Container` (`AppColors.successBg` background, `AppRadius.card`),
  green "What's next?" heading (`AppColors.success`), then 3 rows reusing the
  icon-in-circle + label layout from `_SelfieTipRow` (icon circle uses `AppColors.success` /
  `AppColors.successBg` instead of `secondary`/`surfaceMuted`):
  - `LucideIcons.search` — "Document verification (1–2 days)"
  - `LucideIcons.user` — "Background verification"
  - `LucideIcons.truck` — "Activation and training"
- `PrimaryCtaButton(label: 'Go to Home', trailingIcon: LucideIcons.arrowRight, onPressed: () => Get.offAllNamed(AppRoutes.dashboard))`.
- Bottom step caption, centered: a small circle (`AppColors.successBg` fill, `AppColors.success`
  text) containing "6", followed by "Application Submitted" text (`AppTypography.body`,
  `AppColors.textPrimary`, medium weight). This is local to this screen, not a shared
  component — it's the terminal-state label, distinct from the in-progress
  `StepProgressIndicator` bar used on earlier screens.

## Data

None — no provider, no document/document-status reads. All content is static.

## Testing

- Widget test for `ApplicationSubmittedScreen`: renders the headline, the "What's next?"
  card with its three rows, and the "Go to Home" button; tapping "Go to Home" triggers
  navigation to `AppRoutes.dashboard`.
