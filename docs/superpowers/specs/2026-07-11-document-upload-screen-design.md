# Document Upload Screen — Design

## Context

Step 5 of 5 in the partner registration flow. The route (`/documents`) and a
`PlaceholderScreen` stub are already wired in `app_pages.dart`; `select_city_screen.dart`
already navigates here on continue. Backing infrastructure already exists but is unused:
`DocumentModel` / `DocumentType` / `DocumentStatus` (`lib/models/document_verification/`),
`documentsProvider` (`AsyncNotifier<List<DocumentModel>>`,
`lib/providers/document_verification/documents_provider.dart`), and
`MockDocumentRepository` (`lib/repositories/document_verification/document_repository.dart`).

The existing `DocumentUploadCard` shared widget (chip-badge style, no leading icon) doesn't
match the target visual (icon box left, status right), so this screen introduces a new
`DocumentUploadTile` widget rather than adapting it.

## Scope

- Build `DocumentUploadScreen` and swap it in for the `PlaceholderScreen` stub at
  `AppRoutes.documentUpload`.
- Build `DocumentUploadTile` widget for the 5 document rows.
- Add `image_picker` dependency + camera/gallery picker flow.
- Add a local-only `remove(type)` method to `DocumentsNotifier`.
- Out of scope: profile photo, vehicle photo, and bank proof uploads (not shown in this
  screen's mockup; bank proof belongs to the later Bank Details screen). No real backend
  upload — stays on `MockDocumentRepository`.

## Screen structure

`DocumentUploadScreen` is a `ConsumerStatefulWidget`, matching the shell used by
`vehicle_details_screen.dart`:

`Scaffold` (`AppColors.background`) → `SafeArea` → `ResponsiveFrame(maxWidth: 520)` →
- Back arrow (`IconButtonCustom`, `Get.back()`)
- `StepProgressIndicator(totalSteps: 5, currentStep: 4)` — step order across the flow is
  personalInfo=0, vehicleSelection=1, vehicleDetails=2, deliveryZone=3, documentUpload=4.
- Gradient headline "Upload Documents" (same `RichText` + `ctaGradient` shader pattern as
  other screens), subtitle "Upload clear photos of the following documents".
- Body watching `documentsProvider`:
  - `AsyncLoading` → shimmer placeholder rows (using the existing `shimmer` package).
  - `AsyncError` → retry state (message + button that invalidates/refetches the provider).
  - `AsyncData` → filter the 8 `DocumentType` values down to a fixed, ordered list of 5:
    `aadhaar`, `drivingLicense`, `vehicleRc`, `vehicleInsurance`, `pan`. Render one
    `DocumentUploadTile` per entry.
- `PrimaryCtaButton(label: 'Continue', trailingIcon: LucideIcons.arrowRight)` — always
  enabled.

## `DocumentUploadTile` widget

New file: `lib/features/partner_registration/widgets/document_upload_tile.dart`.

Row layout: leading icon-in-rounded-box (per-doc-type Lucide icon: `idCard`/`car`/
`shieldCheck`/`contact` etc.), title text (+ grey "(Optional)" suffix for PAN only),
trailing status indicator:

| `DocumentStatus`                    | Trailing                                             |
|--------------------------------------|-------------------------------------------------------|
| `notUploaded`                        | Red "Upload" text + red ring icon                      |
| `uploading`                          | Red "Upload" text + small spinner (replaces ring icon) |
| `pendingVerification` / `verified`   | Green "Uploaded" text + green filled check circle      |
| `rejected`                           | Red "Rejected" text + check circle replaced by warning icon; rejection reason caption rendered below the row in `AppTypography.caption` / `AppColors.warning` |

Card container: `AppColors.surface` background, `AppRadius.card`, `AppShadows.card`,
wrapped in `Material`/`InkWell` for tap ripple + `onTap` callback, consistent with
`DocumentUploadCard`'s existing container styling.

## Interactions

- **Tap a `notUploaded`/`rejected` row** → `showModalBottomSheet` with two actions:
  "Take Photo" (opens `ImagePicker().pickImage(source: ImageSource.camera)`) and
  "Choose from Gallery" (`ImageSource.gallery`). On a non-null result, call
  `ref.read(documentsProvider.notifier).upload(type, pickedFile.path)`. The row shows
  `uploading` state (spinner) until the future resolves.
- **Tap an uploaded row** (`pendingVerification`/`verified`) → bottom sheet showing an
  `Image.file(File(doc.fileUrl!))` thumbnail preview with two actions: "Replace" (re-runs
  the camera/gallery picker flow above) and "Remove" (calls a new
  `DocumentsNotifier.remove(type)` that locally resets that document's status to
  `notUploaded` and clears `fileUrl` — no repository call, since `DocumentRepository` has
  no delete endpoint and this mirrors the mock's already-local nature).
- **Upload failure** (defensive — `MockDocumentRepository` always succeeds today, but real
  repositories may not): wrap the `upload` call in try/catch; on error, leave/reset the
  document at `notUploaded` and show a snackbar ("Upload failed, please try again").
- **Continue button**: always enabled. On tap, checks that the 4 required types
  (`aadhaar`, `drivingLicense`, `vehicleRc`, `vehicleInsurance` — PAN excluded) are each in
  `pendingVerification` or `verified` state. If any are missing, show a snackbar listing
  the missing document names and do not navigate. Otherwise, `Get.toNamed(AppRoutes.bankDetails)`.

## `DocumentsNotifier` change

Add to `lib/providers/document_verification/documents_provider.dart`:

```dart
void remove(DocumentType type) {
  state = AsyncData([
    for (final doc in state.value ?? [])
      if (doc.type == type)
        DocumentModel(type: type, status: DocumentStatus.notUploaded)
      else
        doc,
  ]);
}
```

## Dependencies / platform config

- Add `image_picker: ^1.1.2` (or latest compatible) to `pubspec.yaml`.
- iOS `Info.plist`: add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`
  strings.
- Android `AndroidManifest.xml`: `image_picker` handles runtime permission requests itself
  on modern Android; add the `CAMERA` permission entry required for the camera source.

## Error handling summary

- Initial fetch error → retry affordance at screen level.
- Picker returns null (user cancelled) → no-op, no error shown.
- Picker/permission denial → snackbar.
- Upload failure → row reverts to `notUploaded` + snackbar.

## Testing

- Widget test for `DocumentUploadTile` covering the four visual states (not uploaded,
  uploading, uploaded, rejected).
- Widget test for `DocumentUploadScreen`'s Continue validation: blocked with snackbar when
  a required doc is missing, navigates when all 4 required docs are uploaded (PAN omitted).
