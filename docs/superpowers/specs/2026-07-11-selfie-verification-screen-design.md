# Selfie Verification Screen — Design

## Context

New step 6 of the partner registration flow, inserted between Document Upload and Bank
Details. It captures a selfie into the already-existing `DocumentType.profilePhoto` slot
(defined in `lib/models/document_verification/document_model.dart` but unused until now),
reusing the `documentsProvider` / `MockDocumentRepository` infrastructure and the
`image_picker` plumbing built for the Document Upload screen
(`lib/features/partner_registration/widgets/document_upload_actions.dart`).

## Scope

- Add `SelfieVerificationScreen` at a new route `AppRoutes.selfieVerification`, placed
  between `AppRoutes.documentUpload` and `AppRoutes.bankDetails`.
- Change `DocumentUploadScreen`'s Continue target from `AppRoutes.bankDetails` to
  `AppRoutes.selfieVerification`.
- Bump the registration flow from 5 to 6 steps: every existing
  `StepProgressIndicator(totalSteps: 5, ...)` call site becomes `totalSteps: 6` (same
  `currentStep` values), and this new screen uses `currentStep: 5`.
- Add a new `pickAndConfirmSelfie` flow (camera/gallery → confirm preview with
  Retake/Use Photo → upload only on confirm) — distinct from the Document Upload screen's
  `pickAndUploadDocument`, which uploads immediately with no confirmation step.
- Out of scope: no new document type, no backend integration (stays on
  `MockDocumentRepository`).

## Screen structure

`SelfieVerificationScreen` (`ConsumerWidget`), same shell as `DocumentUploadScreen`:

`Scaffold` (`AppColors.background`) → `SafeArea` → `ResponsiveFrame(maxWidth: 520)` →
- Back arrow (`IconButtonCustom`, `Get.back()`).
- `StepProgressIndicator(totalSteps: 6, currentStep: 5)`.
- Gradient headline "Take a Selfie" (same `Text.rich` + `ctaGradient` shader pattern as
  other screens), subtitle "Take a clear selfie for verification".
- `SelfiePreviewFrame` (new widget, `lib/features/partner_registration/widgets/`): a
  circular frame ringed with the blue→green gradient (`CustomPaint` drawing a dashed arc
  with `AppColors.ctaGradient`, matching the mockup's dashed circular border). Shows a
  neutral `LucideIcons.userCircle` placeholder on `AppColors.surfaceMuted` when no photo is
  uploaded, or `Image.file(File(fileUrl))` clipped to a circle once the profile photo's
  status is `pendingVerification`/`verified`.
- Three static tip rows (icon + text, no state): `LucideIcons.user` "Make sure your face is
  clearly visible", `LucideIcons.sun` "Good lighting", `LucideIcons.glasses` "No sunglasses
  or filters" — reuses the same row layout style as `DocumentUploadTile` (icon-in-box +
  text) but without a trailing status, since there's only one photo on this screen.
- `PrimaryCtaButton`: label "Capture" with `LucideIcons.camera` trailing icon while the
  profile photo document is not yet uploaded; becomes label "Continue" with
  `LucideIcons.arrowRight` once it is uploaded.

## Interactions

- **Tap "Capture"** (profile photo not uploaded) → `pickAndConfirmSelfie(context, ref)`:
  1. Reuses the existing "Take Photo / Choose from Gallery" bottom sheet
     (`pickAndUploadDocument`'s sheet UI, factored so both flows share it) to get an
     `ImageSource`, then calls `documentImagePickerProvider` to get a file path.
  2. If a path is returned, shows a confirmation bottom sheet: a preview of the picked
     image (`Image.file`) plus "Retake" and "Use Photo" actions.
  3. "Retake" re-opens the camera/gallery sheet (step 1) without saving anything.
  4. "Use Photo" calls `documentsProvider.notifier.upload(DocumentType.profilePhoto, path)`
     — same try/catch-with-snackbar failure handling as the Document Upload screen.
- **Tap "Continue"** (profile photo uploaded) → `Get.toNamed(AppRoutes.bankDetails)`. Always
  enabled once reached — there's no separate validation step since the screen only unlocks
  "Continue" after a successful capture (mirrors the mockup's single-purpose flow; no
  "skip" path).
- Tapping the preview frame itself when already uploaded also opens the same
  camera/gallery → confirm flow, letting the user retake at any time before continuing.

## Error handling

- Initial `documentsProvider` fetch error → same retry affordance pattern as Document
  Upload (message + retry button that invalidates the provider).
- Picker cancelled (returns null) → no-op.
- Upload failure → snackbar "Upload failed, please try again"; the button stays on
  "Capture" since the profile photo document stays at `notUploaded`.

## Testing

- Widget test for `SelfiePreviewFrame` covering the two states (placeholder icon vs.
  uploaded photo).
- Widget test for `SelfieVerificationScreen`: Capture button opens the source sheet;
  picking a source shows the confirm sheet; "Use Photo" uploads and flips the button to
  "Continue"; "Retake" re-opens the source sheet without uploading; tapping Continue (once
  uploaded) navigates to Bank Details.
