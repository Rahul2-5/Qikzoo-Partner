# Selfie Verification Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Take a Selfie" screen as the new step 6 of partner registration (between Document Upload and Bank Details), capturing a selfie into the existing `DocumentType.profilePhoto` slot with a capture → confirm/retake → save flow.

**Architecture:** A new `SelfieVerificationScreen` (Riverpod `ConsumerWidget`) reuses the `documentsProvider` and `image_picker` plumbing already built for Document Upload. A new `pickAndConfirmSelfie` function (in the existing `document_upload_actions.dart`) adds a confirm/retake step on top of the existing camera/gallery picker before saving. A new `SelfiePreviewFrame` widget renders the circular gradient-ringed photo/placeholder.

**Tech Stack:** Flutter, Riverpod, GetX, `lucide_icons`, `image_picker` (already added).

## Global Constraints

- The registration flow grows from 5 to 6 steps: every existing
  `StepProgressIndicator(totalSteps: 5, ...)` becomes `totalSteps: 6` (same `currentStep`
  values). This screen uses `currentStep: 5`.
- New route `AppRoutes.selfieVerification` sits between `AppRoutes.documentUpload` and
  `AppRoutes.bankDetails`. `DocumentUploadScreen`'s Continue now targets
  `AppRoutes.selfieVerification` instead of `AppRoutes.bankDetails`.
- Reuse `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius` tokens; reuse
  `PrimaryCtaButton` / `OutlinedButtonCustom` for sheet actions (same pattern as
  `ConfirmationDialog`).
- Confirm/retake is mandatory once a photo is picked (`isDismissible` sheet with two
  explicit choices) — no silent no-op path once the picker returns a file.
- No backend integration — stays on `MockDocumentRepository`.

---

### Task 1: Bump the flow to 6 steps and repoint Document Upload's Continue

**Files:**
- Modify: `frontend/lib/core/routes/app_routes.dart`
- Modify: `frontend/lib/features/partner_registration/screens/personal_info_screen.dart`
- Modify: `frontend/lib/features/partner_registration/screens/vehicle_selection_screen.dart`
- Modify: `frontend/lib/features/partner_registration/screens/vehicle_details_screen.dart`
- Modify: `frontend/lib/features/partner_registration/screens/select_city_screen.dart`
- Modify: `frontend/lib/features/partner_registration/screens/document_upload_screen.dart`
- Modify: `frontend/test/features/partner_registration/screens/document_upload_screen_test.dart`

**Interfaces:**
- Produces: `AppRoutes.selfieVerification` (String route constant).

- [ ] **Step 1: Update the existing screen test's expectations first**

In `frontend/test/features/partner_registration/screens/document_upload_screen_test.dart`,
replace the `bankDetails` stub page with a `selfieVerification` stub, and rename/update the
navigation test:

```dart
// In buildApp(), replace:
        GetPage(
          name: AppRoutes.bankDetails,
          page: () => const Scaffold(body: Text('Bank Details Screen')),
        ),
// with:
        GetPage(
          name: AppRoutes.selfieVerification,
          page: () => const Scaffold(body: Text('Selfie Verification Screen')),
        ),
```

```dart
// Replace the "Continue shows a snackbar..." test's final assertion:
    expect(find.text('Bank Details Screen'), findsNothing);
// with:
    expect(find.text('Selfie Verification Screen'), findsNothing);
```

```dart
// Rename and update the third testWidgets:
  testWidgets('Continue navigates to selfie verification once required documents are uploaded', (tester) async {
    // ...unchanged body...
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Selfie Verification Screen'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/partner_registration/screens/document_upload_screen_test.dart`
Expected: FAIL — `AppRoutes.selfieVerification` doesn't exist yet, and
`document_upload_screen.dart` still navigates to `bankDetails`.

- [ ] **Step 3: Add the route constant**

In `frontend/lib/core/routes/app_routes.dart`, add right after `documentUpload`:

```dart
  static const documentUpload = '/documents';
  static const selfieVerification = '/registration/selfie-verification';
```

- [ ] **Step 4: Repoint Document Upload's Continue**

In `frontend/lib/features/partner_registration/screens/document_upload_screen.dart`,
change `_onContinue`:

```dart
    Get.toNamed(AppRoutes.bankDetails);
```

to:

```dart
    Get.toNamed(AppRoutes.selfieVerification);
```

- [ ] **Step 5: Bump `totalSteps` to 6 across the flow**

In each of these five files, change `totalSteps: 5` to `totalSteps: 6` (leave
`currentStep` untouched in each):

- `frontend/lib/features/partner_registration/screens/personal_info_screen.dart` (`currentStep: 0`)
- `frontend/lib/features/partner_registration/screens/vehicle_selection_screen.dart` (`currentStep: 1`)
- `frontend/lib/features/partner_registration/screens/vehicle_details_screen.dart` (`currentStep: 2`)
- `frontend/lib/features/partner_registration/screens/select_city_screen.dart` (`currentStep: 3`)
- `frontend/lib/features/partner_registration/screens/document_upload_screen.dart` (`currentStep: 4`)

- [ ] **Step 6: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/partner_registration/screens/document_upload_screen_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 7: Run the full suite to confirm no regressions**

Run: `cd frontend && flutter test`
Expected: all tests pass.

- [ ] **Step 8: Commit**

```bash
git add frontend/lib/core/routes/app_routes.dart frontend/lib/features/partner_registration/screens/personal_info_screen.dart frontend/lib/features/partner_registration/screens/vehicle_selection_screen.dart frontend/lib/features/partner_registration/screens/vehicle_details_screen.dart frontend/lib/features/partner_registration/screens/select_city_screen.dart frontend/lib/features/partner_registration/screens/document_upload_screen.dart frontend/test/features/partner_registration/screens/document_upload_screen_test.dart
git commit -m "Bump registration flow to 6 steps and add selfie verification route"
```

---

### Task 2: Capture → confirm/retake → save flow (`pickAndConfirmSelfie`)

**Files:**
- Modify: `frontend/lib/features/partner_registration/widgets/document_upload_actions.dart`
- Modify: `frontend/test/features/partner_registration/widgets/document_upload_actions_test.dart`

**Interfaces:**
- Consumes: `documentImagePickerProvider`, `documentsProvider` (existing), `PrimaryCtaButton`, `OutlinedButtonCustom` (existing shared widgets).
- Produces: `Future<ImageSource?> showImageSourceSheet(BuildContext context)` (extracted, reused by `pickAndUploadDocument`), `Future<bool?> showSelfieConfirmSheet(BuildContext context, String path)`, `Future<void> pickAndConfirmSelfie(BuildContext context, WidgetRef ref)`.

- [ ] **Step 1: Write the failing tests**

Add to `frontend/test/features/partner_registration/widgets/document_upload_actions_test.dart` (same `main()`, new `testWidgets` blocks; reuses the existing `FakeDocumentRepository` and `FakeDocumentImagePicker` from this file):

```dart
  testWidgets('Use Photo uploads the profile photo document', (tester) async {
    final container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          FakeDocumentRepository([
            const DocumentModel(type: DocumentType.profilePhoto, status: DocumentStatus.notUploaded),
          ]),
        ),
        documentImagePickerProvider.overrideWithValue(FakeDocumentImagePicker()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(documentsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => pickAndConfirmSelfie(context, ref),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();

    expect(find.text('Use Photo'), findsOneWidget);
    await tester.tap(find.text('Use Photo'));
    await tester.pumpAndSettle();

    final updated = container
        .read(documentsProvider)
        .value!
        .firstWhere((doc) => doc.type == DocumentType.profilePhoto);
    expect(updated.status, DocumentStatus.pendingVerification);
    expect(updated.fileUrl, '/tmp/picked.jpg');
  });

  testWidgets('Retake reopens the source sheet without uploading', (tester) async {
    final container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          FakeDocumentRepository([
            const DocumentModel(type: DocumentType.profilePhoto, status: DocumentStatus.notUploaded),
          ]),
        ),
        documentImagePickerProvider.overrideWithValue(FakeDocumentImagePicker()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(documentsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => pickAndConfirmSelfie(context, ref),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retake'));
    await tester.pumpAndSettle();

    expect(find.text('Take Photo'), findsOneWidget);
    final stillNotUploaded = container
        .read(documentsProvider)
        .value!
        .firstWhere((doc) => doc.type == DocumentType.profilePhoto);
    expect(stillNotUploaded.status, DocumentStatus.notUploaded);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd frontend && flutter test test/features/partner_registration/widgets/document_upload_actions_test.dart`
Expected: FAIL — `pickAndConfirmSelfie` not defined.

- [ ] **Step 3: Extract `showImageSourceSheet` and add the new functions**

In `frontend/lib/features/partner_registration/widgets/document_upload_actions.dart`,
replace the inline bottom sheet inside `pickAndUploadDocument` by extracting it into a
standalone function, then add the confirm sheet and `pickAndConfirmSelfie`. Replace the
whole file with:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/document_verification/document_model.dart';
import '../../../providers/document_verification/documents_provider.dart';
import '../../../repositories/document_verification/document_image_picker.dart';
import '../../../shared/widgets/buttons/outlined_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';

Future<ImageSource?> showImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera, color: AppColors.secondary),
              title: Text('Take Photo', style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: AppColors.secondary),
              title: Text('Choose from Gallery', style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> pickAndUploadDocument(
  BuildContext context,
  WidgetRef ref,
  DocumentType type,
) async {
  final source = await showImageSourceSheet(context);
  if (source == null) return;

  final path = await ref.read(documentImagePickerProvider).pickImage(source);
  if (path == null) return;

  try {
    await ref.read(documentsProvider.notifier).upload(type, path);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed, please try again')),
      );
    }
  }
}

Future<void> showDocumentPreviewSheet(
  BuildContext context,
  WidgetRef ref,
  DocumentModel document,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: Image.file(
                File(document.fileUrl!),
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 96,
                  height: 96,
                  color: AppColors.surfaceMuted,
                  child: const Icon(LucideIcons.fileText, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(LucideIcons.refreshCw, color: AppColors.secondary),
              title: Text('Replace', style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(sheetContext).pop('replace'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: AppColors.error),
              title: Text(
                'Remove',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
              ),
              onTap: () => Navigator.of(sheetContext).pop('remove'),
            ),
          ],
        ),
      ),
    ),
  );

  if (action == 'remove') {
    ref.read(documentsProvider.notifier).remove(document.type);
  } else if (action == 'replace' && context.mounted) {
    await pickAndUploadDocument(context, ref, document.type);
  }
}

Future<bool?> showSelfieConfirmSheet(BuildContext context, String path) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.file(
                File(path),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 120,
                  color: AppColors.surfaceMuted,
                  child: const Icon(
                    LucideIcons.userCircle,
                    color: AppColors.textSecondary,
                    size: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButtonCustom(
                    label: 'Retake',
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryCtaButton(
                    label: 'Use Photo',
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> pickAndConfirmSelfie(BuildContext context, WidgetRef ref) async {
  while (true) {
    final source = await showImageSourceSheet(context);
    if (source == null) return;

    final path = await ref.read(documentImagePickerProvider).pickImage(source);
    if (path == null) return;

    if (!context.mounted) return;
    final useThisPhoto = await showSelfieConfirmSheet(context, path);
    if (useThisPhoto == null) return;
    if (useThisPhoto == false) continue;

    try {
      await ref.read(documentsProvider.notifier).upload(DocumentType.profilePhoto, path);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed, please try again')),
        );
      }
    }
    return;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd frontend && flutter test test/features/partner_registration/widgets/document_upload_actions_test.dart`
Expected: PASS (4 tests — the 2 pre-existing plus the 2 new ones).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/partner_registration/widgets/document_upload_actions.dart frontend/test/features/partner_registration/widgets/document_upload_actions_test.dart
git commit -m "Add capture-confirm-retake flow for the selfie verification document"
```

---

### Task 3: `SelfiePreviewFrame` widget

**Files:**
- Create: `frontend/lib/features/partner_registration/widgets/selfie_preview_frame.dart`
- Test: `frontend/test/features/partner_registration/widgets/selfie_preview_frame_test.dart` (create)

**Interfaces:**
- Consumes: `DocumentModel`, `DocumentStatus` (existing).
- Produces: `class SelfiePreviewFrame extends StatelessWidget { const SelfiePreviewFrame({DocumentModel? profilePhoto}); }`

- [ ] **Step 1: Write the failing test**

```dart
// frontend/test/features/partner_registration/widgets/selfie_preview_frame_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/selfie_preview_frame.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows a placeholder icon when there is no profile photo yet', (tester) async {
    await tester.pumpWidget(wrap(const SelfiePreviewFrame(profilePhoto: null)));

    expect(find.byIcon(LucideIcons.userCircle), findsOneWidget);
  });

  testWidgets('renders an image widget when the profile photo is uploaded', (tester) async {
    await tester.pumpWidget(wrap(const SelfiePreviewFrame(
      profilePhoto: DocumentModel(
        type: DocumentType.profilePhoto,
        status: DocumentStatus.pendingVerification,
        fileUrl: '/tmp/selfie.jpg',
      ),
    )));

    expect(find.byType(Image), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/partner_registration/widgets/selfie_preview_frame_test.dart`
Expected: FAIL — `selfie_preview_frame.dart` does not exist.

- [ ] **Step 3: Implement `SelfiePreviewFrame`**

```dart
// frontend/lib/features/partner_registration/widgets/selfie_preview_frame.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/document_verification/document_model.dart';

class SelfiePreviewFrame extends StatelessWidget {
  final DocumentModel? profilePhoto;

  const SelfiePreviewFrame({super.key, this.profilePhoto});

  bool get _hasPhoto {
    final photo = profilePhoto;
    return photo?.fileUrl != null &&
        (photo!.status == DocumentStatus.pendingVerification ||
            photo.status == DocumentStatus.verified);
  }

  @override
  Widget build(BuildContext context) {
    const size = 180.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DashedGradientRingPainter(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipOval(
            child: _hasPhoto
                ? Image.file(
                    File(profilePhoto!.fileUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceMuted,
        alignment: Alignment.center,
        child: const Icon(
          LucideIcons.userCircle,
          size: 72,
          color: AppColors.textSecondary,
        ),
      );
}

class _DashedGradientRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2 - 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(colors: AppColors.ctaGradient).createShader(rect);

    const dashCount = 24;
    const gapFraction = 0.4;
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * math.pi;
      final sweep = (2 * math.pi / dashCount) * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/partner_registration/widgets/selfie_preview_frame_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/partner_registration/widgets/selfie_preview_frame.dart frontend/test/features/partner_registration/widgets/selfie_preview_frame_test.dart
git commit -m "Add SelfiePreviewFrame widget"
```

---

### Task 4: `SelfieVerificationScreen` assembly and route wiring

**Files:**
- Create: `frontend/lib/features/partner_registration/screens/selfie_verification_screen.dart`
- Modify: `frontend/lib/core/routes/app_pages.dart`
- Test: `frontend/test/features/partner_registration/screens/selfie_verification_screen_test.dart` (create)

**Interfaces:**
- Consumes: `documentsProvider` (existing), `SelfiePreviewFrame` (Task 3), `pickAndConfirmSelfie` (Task 2), `AppRoutes.selfieVerification` (Task 1).
- Produces: `class SelfieVerificationScreen extends ConsumerWidget`.

- [ ] **Step 1: Write the failing test**

```dart
// frontend/test/features/partner_registration/screens/selfie_verification_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/selfie_verification_screen.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';
import 'package:delivery_partner_app/providers/document_verification/documents_provider.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_image_picker.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_repository.dart';

class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository(this._documents);
  List<DocumentModel> _documents;

  @override
  Future<List<DocumentModel>> getDocuments() async => _documents;

  @override
  Future<DocumentModel> uploadDocument(DocumentType type, String filePath) async {
    final updated = DocumentModel(
      type: type,
      status: DocumentStatus.pendingVerification,
      fileUrl: filePath,
    );
    _documents = [
      for (final doc in _documents) if (doc.type == type) updated else doc,
    ];
    return updated;
  }
}

class FakeDocumentImagePicker implements DocumentImagePicker {
  @override
  Future<String?> pickImage(ImageSource source) async => '/tmp/selfie.jpg';
}

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp(List<DocumentModel> documents) {
  return ProviderScope(
    overrides: [
      documentRepositoryProvider.overrideWithValue(FakeDocumentRepository(documents)),
      documentImagePickerProvider.overrideWithValue(FakeDocumentImagePicker()),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.selfieVerification,
      getPages: [
        GetPage(
          name: AppRoutes.selfieVerification,
          page: () => const SelfieVerificationScreen(),
        ),
        GetPage(
          name: AppRoutes.bankDetails,
          page: () => const Scaffold(body: Text('Bank Details Screen')),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('shows Capture initially and the verification tips', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp([
      const DocumentModel(type: DocumentType.profilePhoto, status: DocumentStatus.notUploaded),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Capture'), findsOneWidget);
    expect(find.text('Make sure your face is clearly visible'), findsOneWidget);
    expect(find.text('Good lighting'), findsOneWidget);
    expect(find.text('No sunglasses or filters'), findsOneWidget);
  });

  testWidgets('capturing and using a photo switches Capture to Continue', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp([
      const DocumentModel(type: DocumentType.profilePhoto, status: DocumentStatus.notUploaded),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Capture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Photo'));
    await tester.pumpAndSettle();

    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Continue navigates to bank details once the selfie is uploaded', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp([
      const DocumentModel(
        type: DocumentType.profilePhoto,
        status: DocumentStatus.pendingVerification,
        fileUrl: '/tmp/existing.jpg',
      ),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Bank Details Screen'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/partner_registration/screens/selfie_verification_screen_test.dart`
Expected: FAIL — `selfie_verification_screen.dart` does not exist.

- [ ] **Step 3: Implement `SelfieVerificationScreen`**

```dart
// frontend/lib/features/partner_registration/screens/selfie_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/document_verification/document_model.dart';
import '../../../providers/document_verification/documents_provider.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/step_progress_indicator.dart';
import '../widgets/document_upload_actions.dart';
import '../widgets/selfie_preview_frame.dart';

class SelfieVerificationScreen extends ConsumerWidget {
  const SelfieVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);
    final documents = documentsAsync.valueOrNull ?? const <DocumentModel>[];

    DocumentModel? profilePhoto;
    for (final doc in documents) {
      if (doc.type == DocumentType.profilePhoto) {
        profilePhoto = doc;
        break;
      }
    }

    final isUploaded = profilePhoto != null &&
        (profilePhoto.status == DocumentStatus.pendingVerification ||
            profilePhoto.status == DocumentStatus.verified);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              IconButtonCustom(icon: LucideIcons.arrowLeft, onPressed: () => Get.back()),
              const SizedBox(height: AppSpacing.lg),
              const StepProgressIndicator(totalSteps: 6, currentStep: 5),
              const SizedBox(height: AppSpacing.lg),
              Text.rich(
                TextSpan(
                  style: AppTypography.h1.copyWith(fontSize: 26),
                  children: [
                    const TextSpan(
                      text: 'Take a ',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: 'Selfie',
                      style: TextStyle(
                        foreground: Paint()
                          ..shader = const LinearGradient(colors: AppColors.ctaGradient)
                              .createShader(const Rect.fromLTWH(0, 0, 100, 26)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Take a clear selfie for verification',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: SelfiePreviewFrame(profilePhoto: profilePhoto)),
                      const SizedBox(height: AppSpacing.lg),
                      _SelfieTipRow(
                        icon: LucideIcons.user,
                        label: 'Make sure your face is clearly visible',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SelfieTipRow(icon: LucideIcons.sun, label: 'Good lighting'),
                      const SizedBox(height: AppSpacing.sm),
                      _SelfieTipRow(
                        icon: LucideIcons.glasses,
                        label: 'No sunglasses or filters',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              PrimaryCtaButton(
                label: isUploaded ? 'Continue' : 'Capture',
                trailingIcon: isUploaded ? LucideIcons.arrowRight : LucideIcons.camera,
                onPressed: () => isUploaded
                    ? Get.toNamed(AppRoutes.bankDetails)
                    : pickAndConfirmSelfie(context, ref),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelfieTipRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SelfieTipRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTypography.body)),
      ],
    );
  }
}
```

- [ ] **Step 4: Wire the route**

In `frontend/lib/core/routes/app_pages.dart`, add the import:

```dart
import '../../features/partner_registration/screens/selfie_verification_screen.dart';
```

And add a new `GetPage` between the `documentUpload` and `bankDetails` entries:

```dart
    GetPage(
        name: AppRoutes.documentUpload,
        page: () => const DocumentUploadScreen()),
    GetPage(
        name: AppRoutes.selfieVerification,
        page: () => const SelfieVerificationScreen()),
    GetPage(
        name: AppRoutes.bankDetails,
        page: () => const PlaceholderScreen(title: 'Bank Details')),
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/partner_registration/screens/selfie_verification_screen_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Run the full test suite**

Run: `cd frontend && flutter test`
Expected: all tests pass (existing suite + this plan's new/modified test files).

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/partner_registration/screens/selfie_verification_screen.dart frontend/lib/core/routes/app_pages.dart frontend/test/features/partner_registration/screens/selfie_verification_screen_test.dart
git commit -m "Add SelfieVerificationScreen and wire it into the registration route flow"
```

---

## Manual verification (after all tasks)

`image_picker` needs a real camera/gallery, so once tests are green, run the app and walk
the flow once (device/build-environment permitting):

1. Complete registration through Document Upload; tapping Continue there should land on
   "Take a Selfie" (step 6 of 6 in the progress bar).
2. Tap "Capture" → confirm the Take Photo/Choose from Gallery sheet appears.
3. Pick a photo → confirm the Retake/Use Photo sheet shows the picked image.
4. Tap "Retake" → confirm it reopens the source sheet without saving.
5. Tap "Use Photo" → confirm the circular frame now shows the photo and the button reads
   "Continue".
6. Tap "Continue" → confirm navigation to Bank Details.
