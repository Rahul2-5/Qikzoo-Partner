# Document Upload Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the "Document Upload" screen (step 5 of 5 in partner registration) so a partner can upload Aadhaar, Driving License, Vehicle RC, Insurance, and (optional) PAN via camera/gallery, see per-document status, and continue to Bank Details once required docs are uploaded.

**Architecture:** A new `DocumentUploadScreen` (Riverpod `ConsumerWidget`) replaces the existing `PlaceholderScreen` stub at `AppRoutes.documentUpload`, driven by the already-existing `documentsProvider` (`AsyncNotifier<List<DocumentModel>>`) and `MockDocumentRepository`. A new `DocumentUploadTile` widget renders each row. Picking/uploading and preview/replace/remove are extracted into standalone, provider-injectable functions so they're testable without a real camera or file system.

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod`), GetX (`get`) for navigation, `lucide_icons`, new dependency `image_picker`.

## Global Constraints

- State management: Riverpod, matching `registration_form_provider.dart` / `documents_provider.dart` conventions — no new state library.
- Navigation: GetX (`Get.toNamed` / `Get.back()`), matching every other registration screen.
- Visual tokens: reuse `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows` from `lib/core/theme/` — no new hardcoded colors/spacing.
- Step indicator: `StepProgressIndicator(totalSteps: 5, currentStep: 4)` (personalInfo=0, vehicleSelection=1, vehicleDetails=2, deliveryZone=3, documentUpload=4).
- Displayed documents, fixed order: Aadhaar Card, Driving License, Vehicle RC, Insurance, PAN Card (Optional). Required: Aadhaar, Driving License, Vehicle RC, Insurance. Optional: PAN. `profilePhoto`, `vehiclePhoto`, `bankProof` are out of scope for this screen.
- Continue button is always enabled; tapping it with required docs missing shows a snackbar and does not navigate; navigates to `AppRoutes.bankDetails` once all 4 required docs are `pendingVerification` or `verified`.
- No real backend — stays on `MockDocumentRepository`; "Remove" is local-only (no repository delete endpoint exists).
- New dependency: `image_picker: ^1.1.2`.

---

### Task 1: `DocumentType` display extension (label / icon / optional)

**Files:**
- Modify: `frontend/lib/models/document_verification/document_model.dart`
- Test: `frontend/test/models/document_verification/document_model_test.dart` (create)

**Interfaces:**
- Produces: `extension DocumentTypeDisplay on DocumentType { String get label; IconData get icon; bool get isOptional; }`

- [ ] **Step 1: Write the failing test**

```dart
// frontend/test/models/document_verification/document_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';

void main() {
  group('DocumentTypeDisplay', () {
    test('labels match the document upload screen copy', () {
      expect(DocumentType.aadhaar.label, 'Aadhaar Card');
      expect(DocumentType.drivingLicense.label, 'Driving License');
      expect(DocumentType.vehicleRc.label, 'Vehicle RC');
      expect(DocumentType.vehicleInsurance.label, 'Insurance');
      expect(DocumentType.pan.label, 'PAN Card');
    });

    test('only PAN is optional', () {
      expect(DocumentType.pan.isOptional, isTrue);
      expect(DocumentType.aadhaar.isOptional, isFalse);
      expect(DocumentType.drivingLicense.isOptional, isFalse);
      expect(DocumentType.vehicleRc.isOptional, isFalse);
      expect(DocumentType.vehicleInsurance.isOptional, isFalse);
    });

    test('each displayed type has an icon assigned', () {
      expect(DocumentType.aadhaar.icon, LucideIcons.idCard);
      expect(DocumentType.drivingLicense.icon, LucideIcons.creditCard);
      expect(DocumentType.vehicleRc.icon, LucideIcons.car);
      expect(DocumentType.vehicleInsurance.icon, LucideIcons.shieldCheck);
      expect(DocumentType.pan.icon, LucideIcons.contact);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/models/document_verification/document_model_test.dart`
Expected: FAIL — `DocumentTypeDisplay`/`.label`/`.icon`/`.isOptional` are not defined.

- [ ] **Step 3: Implement the extension**

Add to the bottom of `frontend/lib/models/document_verification/document_model.dart` (and add `import 'package:flutter/material.dart';` at the top, alongside the existing `equatable` import):

```dart
extension DocumentTypeDisplay on DocumentType {
  String get label {
    switch (this) {
      case DocumentType.profilePhoto:
        return 'Profile Photo';
      case DocumentType.aadhaar:
        return 'Aadhaar Card';
      case DocumentType.pan:
        return 'PAN Card';
      case DocumentType.drivingLicense:
        return 'Driving License';
      case DocumentType.vehicleRc:
        return 'Vehicle RC';
      case DocumentType.vehicleInsurance:
        return 'Insurance';
      case DocumentType.vehiclePhoto:
        return 'Vehicle Photo';
      case DocumentType.bankProof:
        return 'Bank Proof';
    }
  }

  bool get isOptional => this == DocumentType.pan;

  IconData get icon {
    switch (this) {
      case DocumentType.profilePhoto:
        return LucideIcons.userCircle;
      case DocumentType.aadhaar:
        return LucideIcons.idCard;
      case DocumentType.pan:
        return LucideIcons.contact;
      case DocumentType.drivingLicense:
        return LucideIcons.creditCard;
      case DocumentType.vehicleRc:
        return LucideIcons.car;
      case DocumentType.vehicleInsurance:
        return LucideIcons.shieldCheck;
      case DocumentType.vehiclePhoto:
        return LucideIcons.camera;
      case DocumentType.bankProof:
        return LucideIcons.landmark;
    }
  }
}
```

Also add `import 'package:lucide_icons/lucide_icons.dart';` to that file's imports.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/models/document_verification/document_model_test.dart`
Expected: PASS (3 tests). If an icon name doesn't exist in the installed `lucide_icons` version, run `flutter analyze` to find the exact error and swap in the nearest equivalent icon constant from that package.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/models/document_verification/document_model.dart frontend/test/models/document_verification/document_model_test.dart
git commit -m "Add DocumentType display extension (label, icon, optional flag)"
```

---

### Task 2: `DocumentsNotifier.remove()`

**Files:**
- Modify: `frontend/lib/providers/document_verification/documents_provider.dart`
- Test: `frontend/test/providers/document_verification/documents_provider_test.dart` (create)

**Interfaces:**
- Consumes: `DocumentModel`, `DocumentType`, `DocumentStatus` (Task 1's file), `DocumentRepository` (`frontend/lib/repositories/document_verification/document_repository.dart`).
- Produces: `void DocumentsNotifier.remove(DocumentType type)` — resets that document to `DocumentStatus.notUploaded` with `fileUrl: null`, local state only (no repository call).

- [ ] **Step 1: Write the failing test**

```dart
// frontend/test/providers/document_verification/documents_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';
import 'package:delivery_partner_app/providers/document_verification/documents_provider.dart';
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

void main() {
  test('remove resets a document back to notUploaded and clears its file', () async {
    final container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          FakeDocumentRepository([
            const DocumentModel(
              type: DocumentType.aadhaar,
              status: DocumentStatus.pendingVerification,
              fileUrl: '/tmp/aadhaar.jpg',
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(documentsProvider.future);
    container.read(documentsProvider.notifier).remove(DocumentType.aadhaar);

    final updated = container.read(documentsProvider).value!.single;
    expect(updated.status, DocumentStatus.notUploaded);
    expect(updated.fileUrl, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/providers/document_verification/documents_provider_test.dart`
Expected: FAIL — `remove` method not defined on `DocumentsNotifier`.

- [ ] **Step 3: Implement `remove`**

Add this method to `DocumentsNotifier` in `frontend/lib/providers/document_verification/documents_provider.dart` (alongside the existing `upload` method):

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

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/providers/document_verification/documents_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/providers/document_verification/documents_provider.dart frontend/test/providers/document_verification/documents_provider_test.dart
git commit -m "Add local remove() to DocumentsNotifier"
```

---

### Task 3: `DocumentUploadTile` widget

**Files:**
- Create: `frontend/lib/features/partner_registration/widgets/document_upload_tile.dart`
- Test: `frontend/test/features/partner_registration/widgets/document_upload_tile_test.dart` (create)

**Interfaces:**
- Consumes: `DocumentModel`, `DocumentStatus`, `DocumentTypeDisplay` extension (Task 1).
- Produces: `class DocumentUploadTile extends StatelessWidget { const DocumentUploadTile({required DocumentModel document, required VoidCallback onTap}); }`

- [ ] **Step 1: Write the failing test**

```dart
// frontend/test/features/partner_registration/widgets/document_upload_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/document_upload_tile.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('not uploaded shows Upload label and is tappable', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(DocumentUploadTile(
      document: const DocumentModel(type: DocumentType.aadhaar, status: DocumentStatus.notUploaded),
      onTap: () => tapped = true,
    )));

    expect(find.text('Upload'), findsOneWidget);
    await tester.tap(find.byType(DocumentUploadTile));
    expect(tapped, isTrue);
  });

  testWidgets('uploading shows a spinner instead of the status icon', (tester) async {
    await tester.pumpWidget(wrap(DocumentUploadTile(
      document: const DocumentModel(type: DocumentType.aadhaar, status: DocumentStatus.uploading),
      onTap: () {},
    )));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('uploaded shows Uploaded label', (tester) async {
    await tester.pumpWidget(wrap(DocumentUploadTile(
      document: const DocumentModel(
        type: DocumentType.aadhaar,
        status: DocumentStatus.pendingVerification,
        fileUrl: '/tmp/a.jpg',
      ),
      onTap: () {},
    )));

    expect(find.text('Uploaded'), findsOneWidget);
  });

  testWidgets('rejected shows the rejection reason', (tester) async {
    await tester.pumpWidget(wrap(DocumentUploadTile(
      document: const DocumentModel(
        type: DocumentType.aadhaar,
        status: DocumentStatus.rejected,
        rejectionReason: 'Image is blurry',
      ),
      onTap: () {},
    )));

    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Image is blurry'), findsOneWidget);
  });

  testWidgets('optional document shows the (Optional) suffix', (tester) async {
    await tester.pumpWidget(wrap(DocumentUploadTile(
      document: const DocumentModel(type: DocumentType.pan, status: DocumentStatus.notUploaded),
      onTap: () {},
    )));

    expect(find.textContaining('(Optional)'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/partner_registration/widgets/document_upload_tile_test.dart`
Expected: FAIL — `document_upload_tile.dart` does not exist.

- [ ] **Step 3: Implement `DocumentUploadTile`**

```dart
// frontend/lib/features/partner_registration/widgets/document_upload_tile.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/document_verification/document_model.dart';

class DocumentUploadTile extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;

  const DocumentUploadTile({
    super.key,
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = document.type;
    final isUploaded = document.status == DocumentStatus.pendingVerification ||
        document.status == DocumentStatus.verified;
    final isUploading = document.status == DocumentStatus.uploading;
    final isRejected = document.status == DocumentStatus.rejected;

    final Color statusColor = isUploaded
        ? AppColors.success
        : isRejected
            ? AppColors.error
            : AppColors.warning;
    final String statusLabel = isUploaded
        ? 'Uploaded'
        : isRejected
            ? 'Rejected'
            : 'Upload';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Icon(type.icon, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodyMedium,
                        children: [
                          TextSpan(text: type.label),
                          if (type.isOptional)
                            TextSpan(text: '  (Optional)', style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    statusLabel,
                    style: AppTypography.bodyMedium.copyWith(color: statusColor),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isUploaded
                              ? LucideIcons.checkCircle2
                              : isRejected
                                  ? LucideIcons.alertTriangle
                                  : LucideIcons.circle,
                          color: statusColor,
                          size: 22,
                        ),
                ],
              ),
              if (isRejected && document.rejectionReason != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  document.rejectionReason!,
                  style: AppTypography.caption.copyWith(color: AppColors.warning),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/partner_registration/widgets/document_upload_tile_test.dart`
Expected: PASS (5 tests). If any Lucide icon constant doesn't compile, run `flutter analyze` and substitute the nearest valid icon name from the installed `lucide_icons` package (keep the same visual intent: check/uploaded, ring/pending, warning/rejected).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/partner_registration/widgets/document_upload_tile.dart frontend/test/features/partner_registration/widgets/document_upload_tile_test.dart
git commit -m "Add DocumentUploadTile widget"
```

---

### Task 4: Image picker abstraction + take-photo/choose-gallery flow

**Files:**
- Create: `frontend/lib/repositories/document_verification/document_image_picker.dart`
- Create: `frontend/lib/features/partner_registration/widgets/document_upload_actions.dart`
- Modify: `frontend/pubspec.yaml`
- Modify: `frontend/ios/Runner/Info.plist`
- Modify: `frontend/android/app/src/main/AndroidManifest.xml`
- Test: `frontend/test/features/partner_registration/widgets/document_upload_actions_test.dart` (create)

**Interfaces:**
- Consumes: `documentsProvider` / `DocumentsNotifier.upload` (existing), `DocumentType`.
- Produces: `abstract class DocumentImagePicker { Future<String?> pickImage(ImageSource source); }`, `final documentImagePickerProvider = Provider<DocumentImagePicker>(...)`, `Future<void> pickAndUploadDocument(BuildContext context, WidgetRef ref, DocumentType type)`.

- [ ] **Step 1: Add the `image_picker` dependency**

In `frontend/pubspec.yaml`, add under `dependencies:` (alphabetically near `google_fonts`/`intl`, matching the existing loose ordering in that file):

```yaml
  image_picker: ^1.1.2
```

Run: `cd frontend && flutter pub get`
Expected: resolves successfully, `pubspec.lock` updated.

- [ ] **Step 2: Add platform permission strings**

In `frontend/ios/Runner/Info.plist`, add these two keys right after the existing `NSLocationWhenInUseUsageDescription` entry (currently lines 29-30):

```xml
	<key>NSCameraUsageDescription</key>
	<string>Qikzoo Partner needs camera access to capture your documents.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>Qikzoo Partner needs photo library access to upload your documents.</string>
```

In `frontend/android/app/src/main/AndroidManifest.xml`, add this permission next to the existing location permissions (currently lines 2-3):

```xml
    <uses-permission android:name="android.permission.CAMERA"/>
```

- [ ] **Step 3: Write the failing test**

```dart
// frontend/test/features/partner_registration/widgets/document_upload_actions_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/document_upload_actions.dart';
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
  Future<String?> pickImage(ImageSource source) async => '/tmp/picked.jpg';
}

void main() {
  testWidgets('picking Take Photo uploads the document', (tester) async {
    final container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          FakeDocumentRepository([
            const DocumentModel(type: DocumentType.aadhaar, status: DocumentStatus.notUploaded),
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
                onPressed: () => pickAndUploadDocument(context, ref, DocumentType.aadhaar),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);

    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();

    final updated = container
        .read(documentsProvider)
        .value!
        .firstWhere((doc) => doc.type == DocumentType.aadhaar);
    expect(updated.status, DocumentStatus.pendingVerification);
    expect(updated.fileUrl, '/tmp/picked.jpg');
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/partner_registration/widgets/document_upload_actions_test.dart`
Expected: FAIL — `document_upload_actions.dart` / `document_image_picker.dart` don't exist.

- [ ] **Step 5: Implement the picker abstraction**

```dart
// frontend/lib/repositories/document_verification/document_image_picker.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

abstract class DocumentImagePicker {
  Future<String?> pickImage(ImageSource source);
}

class DeviceDocumentImagePicker implements DocumentImagePicker {
  @override
  Future<String?> pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    return file?.path;
  }
}

final documentImagePickerProvider =
    Provider<DocumentImagePicker>((ref) => DeviceDocumentImagePicker());
```

- [ ] **Step 6: Implement `pickAndUploadDocument` and its bottom sheet**

```dart
// frontend/lib/features/partner_registration/widgets/document_upload_actions.dart
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

Future<void> pickAndUploadDocument(
  BuildContext context,
  WidgetRef ref,
  DocumentType type,
) async {
  final source = await showModalBottomSheet<ImageSource>(
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
```

- [ ] **Step 7: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/partner_registration/widgets/document_upload_actions_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add frontend/pubspec.yaml frontend/pubspec.lock frontend/ios/Runner/Info.plist frontend/android/app/src/main/AndroidManifest.xml frontend/lib/repositories/document_verification/document_image_picker.dart frontend/lib/features/partner_registration/widgets/document_upload_actions.dart frontend/test/features/partner_registration/widgets/document_upload_actions_test.dart
git commit -m "Add image picker abstraction and take-photo/choose-gallery flow"
```

---

### Task 5: Preview / Replace / Remove sheet for uploaded documents

**Files:**
- Modify: `frontend/lib/features/partner_registration/widgets/document_upload_actions.dart`
- Test: `frontend/test/features/partner_registration/widgets/document_upload_actions_test.dart` (extend)

**Interfaces:**
- Consumes: `pickAndUploadDocument` (Task 4, same file), `DocumentsNotifier.remove` (Task 2).
- Produces: `Future<void> showDocumentPreviewSheet(BuildContext context, WidgetRef ref, DocumentModel document)`.

- [ ] **Step 1: Write the failing test**

Add to `frontend/test/features/partner_registration/widgets/document_upload_actions_test.dart` (same `main()`, new `testWidgets` block):

```dart
  testWidgets('Remove resets the document to notUploaded', (tester) async {
    final container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          FakeDocumentRepository([
            const DocumentModel(
              type: DocumentType.aadhaar,
              status: DocumentStatus.pendingVerification,
              fileUrl: '/tmp/a.jpg',
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final documents = await container.read(documentsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDocumentPreviewSheet(context, ref, documents.first),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Replace'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    final updated = container.read(documentsProvider).value!.single;
    expect(updated.status, DocumentStatus.notUploaded);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/partner_registration/widgets/document_upload_actions_test.dart`
Expected: FAIL — `showDocumentPreviewSheet` not defined.

- [ ] **Step 3: Implement `showDocumentPreviewSheet`**

Add `import 'dart:io';` to the top of `frontend/lib/features/partner_registration/widgets/document_upload_actions.dart`, then append:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/partner_registration/widgets/document_upload_actions_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/partner_registration/widgets/document_upload_actions.dart frontend/test/features/partner_registration/widgets/document_upload_actions_test.dart
git commit -m "Add preview/replace/remove sheet for uploaded documents"
```

---

### Task 6: `DocumentUploadScreen` assembly and route wiring

**Files:**
- Create: `frontend/lib/features/partner_registration/screens/document_upload_screen.dart`
- Modify: `frontend/lib/core/routes/app_pages.dart`
- Test: `frontend/test/features/partner_registration/screens/document_upload_screen_test.dart` (create)

**Interfaces:**
- Consumes: `documentsProvider` (Task 2), `DocumentUploadTile` (Task 3), `pickAndUploadDocument` / `showDocumentPreviewSheet` (Tasks 4/5), `DocumentTypeDisplay` (Task 1).
- Produces: `class DocumentUploadScreen extends ConsumerWidget`, top-level `const documentDisplayOrder = [...]` and `List<String> missingRequiredDocumentLabels(List<DocumentModel> documents)`.

- [ ] **Step 1: Write the failing test**

```dart
// frontend/test/features/partner_registration/screens/document_upload_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/document_upload_screen.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';
import 'package:delivery_partner_app/providers/document_verification/documents_provider.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_repository.dart';

class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository(this._documents);
  final List<DocumentModel> _documents;

  @override
  Future<List<DocumentModel>> getDocuments() async => _documents;

  @override
  Future<DocumentModel> uploadDocument(DocumentType type, String filePath) async {
    return DocumentModel(type: type, status: DocumentStatus.pendingVerification, fileUrl: filePath);
  }
}

Widget buildApp(List<DocumentModel> documents) {
  return ProviderScope(
    overrides: [
      documentRepositoryProvider.overrideWithValue(FakeDocumentRepository(documents)),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.documentUpload,
      getPages: [
        GetPage(name: AppRoutes.documentUpload, page: () => const DocumentUploadScreen()),
        GetPage(
          name: AppRoutes.bankDetails,
          page: () => const Scaffold(body: Text('Bank Details Screen')),
        ),
      ],
    ),
  );
}

void main() {
  test('missingRequiredDocumentLabels lists only missing required docs, PAN excluded', () {
    final documents = [
      const DocumentModel(type: DocumentType.aadhaar, status: DocumentStatus.pendingVerification),
      const DocumentModel(type: DocumentType.drivingLicense, status: DocumentStatus.notUploaded),
      const DocumentModel(type: DocumentType.vehicleRc, status: DocumentStatus.verified),
      const DocumentModel(type: DocumentType.vehicleInsurance, status: DocumentStatus.rejected),
      const DocumentModel(type: DocumentType.pan, status: DocumentStatus.notUploaded),
    ];

    expect(
      missingRequiredDocumentLabels(documents),
      ['Driving License', 'Insurance'],
    );
  });

  testWidgets('renders all five documents in order', (tester) async {
    await tester.pumpWidget(buildApp(
      DocumentType.values
          .map((type) => DocumentModel(type: type, status: DocumentStatus.notUploaded))
          .toList(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Aadhaar Card'), findsOneWidget);
    expect(find.text('Driving License'), findsOneWidget);
    expect(find.text('Vehicle RC'), findsOneWidget);
    expect(find.text('Insurance'), findsOneWidget);
    expect(find.textContaining('PAN Card'), findsOneWidget);
  });

  testWidgets('Continue shows a snackbar listing missing required documents', (tester) async {
    await tester.pumpWidget(buildApp(
      DocumentType.values
          .map((type) => DocumentModel(type: type, status: DocumentStatus.notUploaded))
          .toList(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aadhaar Card'), findsWidgets);
    expect(find.text('Bank Details Screen'), findsNothing);
  });

  testWidgets('Continue navigates to bank details once required documents are uploaded', (tester) async {
    const requiredTypes = [
      DocumentType.aadhaar,
      DocumentType.drivingLicense,
      DocumentType.vehicleRc,
      DocumentType.vehicleInsurance,
    ];
    final documents = DocumentType.values.map((type) {
      final isRequired = requiredTypes.contains(type);
      return DocumentModel(
        type: type,
        status: isRequired ? DocumentStatus.pendingVerification : DocumentStatus.notUploaded,
        fileUrl: isRequired ? '/tmp/${type.name}.jpg' : null,
      );
    }).toList();

    await tester.pumpWidget(buildApp(documents));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Bank Details Screen'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/partner_registration/screens/document_upload_screen_test.dart`
Expected: FAIL — `document_upload_screen.dart` does not exist.

- [ ] **Step 3: Implement `DocumentUploadScreen`**

```dart
// frontend/lib/features/partner_registration/screens/document_upload_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/document_verification/document_model.dart';
import '../../../providers/document_verification/documents_provider.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/step_progress_indicator.dart';
import '../widgets/document_upload_actions.dart';
import '../widgets/document_upload_tile.dart';

const documentDisplayOrder = [
  DocumentType.aadhaar,
  DocumentType.drivingLicense,
  DocumentType.vehicleRc,
  DocumentType.vehicleInsurance,
  DocumentType.pan,
];

const _requiredDocumentTypes = [
  DocumentType.aadhaar,
  DocumentType.drivingLicense,
  DocumentType.vehicleRc,
  DocumentType.vehicleInsurance,
];

bool _isUploaded(DocumentStatus status) =>
    status == DocumentStatus.pendingVerification || status == DocumentStatus.verified;

List<String> missingRequiredDocumentLabels(List<DocumentModel> documents) {
  final byType = {for (final doc in documents) doc.type: doc};
  return [
    for (final type in _requiredDocumentTypes)
      if (!_isUploaded(byType[type]?.status ?? DocumentStatus.notUploaded)) type.label,
  ];
}

class DocumentUploadScreen extends ConsumerWidget {
  const DocumentUploadScreen({super.key});

  void _onContinue(BuildContext context, List<DocumentModel> documents) {
    final missing = missingRequiredDocumentLabels(documents);
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload: ${missing.join(', ')}')),
      );
      return;
    }
    Get.toNamed(AppRoutes.bankDetails);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);

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
              const StepProgressIndicator(totalSteps: 5, currentStep: 4),
              const SizedBox(height: AppSpacing.lg),
              RichText(
                text: TextSpan(
                  style: AppTypography.h1.copyWith(fontSize: 26),
                  children: [
                    const TextSpan(
                      text: 'Upload ',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: 'Documents',
                      style: TextStyle(
                        foreground: Paint()
                          ..shader = const LinearGradient(colors: AppColors.ctaGradient)
                              .createShader(const Rect.fromLTWH(0, 0, 160, 26)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Upload clear photos of the following documents',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: documentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load documents', style: AppTypography.body),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: () => ref.invalidate(documentsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (documents) {
                    final byType = {for (final doc in documents) doc.type: doc};
                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: documentDisplayOrder.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final type = documentDisplayOrder[index];
                        final document = byType[type] ??
                            DocumentModel(type: type, status: DocumentStatus.notUploaded);
                        final isUploaded = _isUploaded(document.status);
                        return DocumentUploadTile(
                          document: document,
                          onTap: () => isUploaded
                              ? showDocumentPreviewSheet(context, ref, document)
                              : pickAndUploadDocument(context, ref, type),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryCtaButton(
                label: 'Continue',
                trailingIcon: LucideIcons.arrowRight,
                onPressed: () => _onContinue(context, documentsAsync.valueOrNull ?? []),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Wire the route**

In `frontend/lib/core/routes/app_pages.dart`, add the import:

```dart
import '../../features/partner_registration/screens/document_upload_screen.dart';
```

And replace:

```dart
    GetPage(
        name: AppRoutes.documentUpload,
        page: () => const PlaceholderScreen(title: 'Document Upload')),
```

with:

```dart
    GetPage(
        name: AppRoutes.documentUpload,
        page: () => const DocumentUploadScreen()),
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/partner_registration/screens/document_upload_screen_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 6: Run the full test suite**

Run: `cd frontend && flutter test`
Expected: all tests pass (existing suite + the 6 new/modified test files from this plan).

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/partner_registration/screens/document_upload_screen.dart frontend/lib/core/routes/app_pages.dart frontend/test/features/partner_registration/screens/document_upload_screen_test.dart
git commit -m "Add DocumentUploadScreen and wire it into the documents route"
```

---

## Manual verification (after all tasks)

Since `image_picker` needs a real device/simulator camera and photo library, run the app (`flutter run`) and manually walk the flow once tests are green:

1. Navigate to `/documents` (via the registration flow, or `Get.toNamed(AppRoutes.documentUpload)` for a quick check).
2. Tap an "Upload" row → confirm the "Take Photo / Choose from Gallery" sheet appears, and picking a photo flips the row to "Uploaded" with a green check.
3. Tap an "Uploaded" row → confirm the preview sheet shows the photo thumbnail, "Replace" re-opens the picker, "Remove" flips the row back to red "Upload".
4. Tap "Continue" with docs missing → confirm the snackbar names the missing documents and the screen does not navigate.
5. Upload all 4 required docs, tap "Continue" → confirm navigation to Bank Details (currently a placeholder screen).
