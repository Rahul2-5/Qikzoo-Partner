# Application Submitted Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the final "Application Submitted" confirmation screen to the partner registration flow, reached from Selfie Verification's Continue button, with a "Go to Home" button that clears the nav stack to the dashboard.

**Architecture:** A static (no provider/state) `StatelessWidget` screen following the exact shell pattern (`Scaffold` → `SafeArea` → `ResponsiveFrame`) used by `DocumentUploadScreen` and `SelfieVerificationScreen`. A new small illustration widget (`SubmittedIllustration`) is built from `Icon`/`Container` composition (project has no image assets for this). Wired into `AppRoutes`/`AppPages`, and `SelfieVerificationScreen`'s Continue target is repointed to it.

**Tech Stack:** Flutter, GetX (routing), Riverpod (unused by this screen but present in the app), `lucide_icons`, `flutter_test`.

## Global Constraints

- Package name for imports in tests: `delivery_partner_app` (see `test/features/partner_registration/screens/selfie_verification_screen_test.dart:6-11`).
- Theme tokens only — no hardcoded colors/spacing/radii. Use `AppColors`, `AppSpacing`, `AppRadius`, `AppTypography` from `lib/core/theme/`.
- Route constants live in `lib/core/routes/app_routes.dart`; pages are registered in `lib/core/routes/app_pages.dart`.
- No new dependencies.

---

### Task 1: Add route constant and register the page

**Files:**
- Modify: `frontend/lib/core/routes/app_routes.dart:14-15`
- Modify: `frontend/lib/core/routes/app_pages.dart`

**Interfaces:**
- Produces: `AppRoutes.applicationSubmitted` (`String`, value `'/registration/application-submitted'`), consumed by Task 2's screen and Task 3's navigation wiring.

- [ ] **Step 1: Add the route constant**

In `frontend/lib/core/routes/app_routes.dart`, add a new constant right after `selfieVerification` (currently line 15):

```dart
  static const selfieVerification = '/registration/selfie-verification';
  static const applicationSubmitted = '/registration/application-submitted';
```

- [ ] **Step 2: Register a placeholder GetPage so the app still compiles**

In `frontend/lib/core/routes/app_pages.dart`, add the import and a `GetPage` entry right after the `selfieVerification` entry (Task 2 will replace the placeholder with the real screen):

```dart
import '../../features/partner_registration/screens/application_submitted_screen.dart';
```

```dart
    GetPage(
        name: AppRoutes.selfieVerification,
        page: () => const SelfieVerificationScreen()),
    GetPage(
        name: AppRoutes.applicationSubmitted,
        page: () => const ApplicationSubmittedScreen()),
```

Note: this import will fail to resolve until Task 2 creates the file — that's expected; Task 2 is next and unblocks the build. Do not run `flutter analyze` until after Task 2.

- [ ] **Step 3: Commit**

```bash
cd frontend
git add lib/core/routes/app_routes.dart lib/core/routes/app_pages.dart
git commit -m "Add applicationSubmitted route constant and page registration"
```

---

### Task 2: Build the `SubmittedIllustration` widget

**Files:**
- Create: `frontend/lib/features/partner_registration/widgets/submitted_illustration.dart`
- Test: `frontend/test/features/partner_registration/widgets/submitted_illustration_test.dart`

**Interfaces:**
- Produces: `class SubmittedIllustration extends StatelessWidget` with a `const SubmittedIllustration({super.key})` constructor, no parameters. Consumed by Task 3's screen.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/partner_registration/widgets/submitted_illustration_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/submitted_illustration.dart';

void main() {
  testWidgets('renders the checklist checks and the success badge check', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SubmittedIllustration())),
    );

    // 5 checklist-row checks + 1 big badge check.
    expect(find.byIcon(LucideIcons.check), findsNWidgets(6));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/partner_registration/widgets/submitted_illustration_test.dart`
Expected: FAIL — `Target of URI doesn't exist` / compile error, since the widget file doesn't exist yet.

- [ ] **Step 3: Write the widget**

Create `frontend/lib/features/partner_registration/widgets/submitted_illustration.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class SubmittedIllustration extends StatelessWidget {
  const SubmittedIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _dot(top: 10, left: 20, color: AppColors.secondary, size: 8),
          _dot(top: 30, left: 60, color: AppColors.accent, size: 6),
          _dot(top: 20, right: 20, color: AppColors.secondary, size: 8),
          _dot(top: 40, right: 55, color: AppColors.warning, size: 6),
          _dot(bottom: 30, left: 10, color: AppColors.warning, size: 8),
          _dot(bottom: 15, right: 15, color: AppColors.accent, size: 8),
          Container(
            width: 140,
            height: 170,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.secondary, width: 2),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.check, size: 10, color: AppColors.success),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            child: Container(
              width: 44,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.check, size: 26, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/partner_registration/widgets/submitted_illustration_test.dart`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
cd frontend
git add lib/features/partner_registration/widgets/submitted_illustration.dart test/features/partner_registration/widgets/submitted_illustration_test.dart
git commit -m "Add SubmittedIllustration widget for the Application Submitted screen"
```

---

### Task 3: Build `ApplicationSubmittedScreen` and wire navigation

**Files:**
- Create: `frontend/lib/features/partner_registration/screens/application_submitted_screen.dart`
- Modify: `frontend/lib/features/partner_registration/screens/selfie_verification_screen.dart:101-106`
- Test: `frontend/test/features/partner_registration/screens/application_submitted_screen_test.dart`

**Interfaces:**
- Consumes: `AppRoutes.applicationSubmitted` (Task 1), `SubmittedIllustration` (Task 2, no params), `AppRoutes.dashboard` (existing), `IconButtonCustom`, `PrimaryCtaButton`, `ResponsiveFrame` (existing shared widgets).
- Produces: `class ApplicationSubmittedScreen extends StatelessWidget` with `const ApplicationSubmittedScreen({super.key})`, no parameters.

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/partner_registration/screens/application_submitted_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/application_submitted_screen.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp() {
  return GetMaterialApp(
    initialRoute: AppRoutes.applicationSubmitted,
    getPages: [
      GetPage(
        name: AppRoutes.applicationSubmitted,
        page: () => const ApplicationSubmittedScreen(),
      ),
      GetPage(
        name: AppRoutes.dashboard,
        page: () => const Scaffold(body: Text('Dashboard Screen')),
      ),
    ],
  );
}

void main() {
  testWidgets('renders the confirmation copy and next-steps card', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Application Submitted'), findsWidgets);
    expect(
      find.text('We will verify your details and get back to you soon.'),
      findsOneWidget,
    );
    expect(find.text('Document verification (1–2 days)'), findsOneWidget);
    expect(find.text('Background verification'), findsOneWidget);
    expect(find.text('Activation and training'), findsOneWidget);
    expect(find.text('Go to Home'), findsOneWidget);
  });

  testWidgets('Go to Home navigates to the dashboard', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go to Home'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/partner_registration/screens/application_submitted_screen_test.dart`
Expected: FAIL — compile error, `application_submitted_screen.dart` doesn't exist yet.

- [ ] **Step 3: Write the screen**

Create `frontend/lib/features/partner_registration/screens/application_submitted_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/submitted_illustration.dart';

class ApplicationSubmittedScreen extends StatelessWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              Text.rich(
                TextSpan(
                  style: AppTypography.h1.copyWith(fontSize: 26),
                  children: [
                    const TextSpan(
                      text: 'Application ',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: 'Submitted',
                      style: TextStyle(
                        foreground: Paint()
                          ..shader = const LinearGradient(colors: AppColors.ctaGradient)
                              .createShader(const Rect.fromLTWH(0, 0, 180, 26)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const Center(child: SubmittedIllustration()),
                      const SizedBox(height: AppSpacing.lg),
                      Text.rich(
                        TextSpan(
                          style: AppTypography.h2.copyWith(fontSize: 20),
                          children: [
                            const TextSpan(
                              text: 'Your application has been submitted ',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            TextSpan(
                              text: 'successfully!',
                              style: TextStyle(
                                foreground: Paint()
                                  ..shader = const LinearGradient(colors: AppColors.ctaGradient)
                                      .createShader(const Rect.fromLTWH(0, 0, 140, 20)),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'We will verify your details and get back to you soon.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "What's next?",
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.success),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const _NextStepRow(
                              icon: LucideIcons.search,
                              label: 'Document verification (1–2 days)',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const _NextStepRow(
                              icon: LucideIcons.user,
                              label: 'Background verification',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const _NextStepRow(
                              icon: LucideIcons.truck,
                              label: 'Activation and training',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              PrimaryCtaButton(
                label: 'Go to Home',
                trailingIcon: LucideIcons.arrowRight,
                onPressed: () => Get.offAllNamed(AppRoutes.dashboard),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.successBg,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '6',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Application Submitted',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextStepRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _NextStepRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.success, size: 16),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTypography.body)),
      ],
    );
  }
}
```

- [ ] **Step 4: Run the screen test to verify it passes**

Run: `cd frontend && flutter test test/features/partner_registration/screens/application_submitted_screen_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Repoint Selfie Verification's Continue button**

In `frontend/lib/features/partner_registration/screens/selfie_verification_screen.dart:101-106`, change:

```dart
              PrimaryCtaButton(
                label: isUploaded ? 'Continue' : 'Capture',
                trailingIcon: isUploaded ? LucideIcons.arrowRight : LucideIcons.camera,
                onPressed: () => isUploaded
                    ? Get.toNamed(AppRoutes.bankDetails)
                    : pickAndConfirmSelfie(context, ref),
              ),
```

to:

```dart
              PrimaryCtaButton(
                label: isUploaded ? 'Continue' : 'Capture',
                trailingIcon: isUploaded ? LucideIcons.arrowRight : LucideIcons.camera,
                onPressed: () => isUploaded
                    ? Get.toNamed(AppRoutes.applicationSubmitted)
                    : pickAndConfirmSelfie(context, ref),
              ),
```

- [ ] **Step 6: Update the existing selfie screen test's expectation**

In `frontend/test/features/partner_registration/screens/selfie_verification_screen_test.dart`, the third test (`'Continue navigates to bank details once the selfie is uploaded'`) currently expects `AppRoutes.bankDetails`'s placeholder page. Update it to target `AppRoutes.applicationSubmitted` instead, since that's now the Continue target. Replace lines 46-66 (`buildApp`) and the third test (lines 99-114):

```dart
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
          name: AppRoutes.applicationSubmitted,
          page: () => const Scaffold(body: Text('Application Submitted Screen')),
        ),
      ],
    ),
  );
}
```

```dart
  testWidgets('Continue navigates to application submitted once the selfie is uploaded', (tester) async {
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

    expect(find.text('Application Submitted Screen'), findsOneWidget);
  });
```

- [ ] **Step 7: Run the full partner_registration test suite**

Run: `cd frontend && flutter test test/features/partner_registration`
Expected: PASS, all tests green (no reference to `AppRoutes.bankDetails` remains in this test file).

- [ ] **Step 8: Commit**

```bash
cd frontend
git add lib/features/partner_registration/screens/application_submitted_screen.dart lib/features/partner_registration/screens/selfie_verification_screen.dart test/features/partner_registration/screens/application_submitted_screen_test.dart test/features/partner_registration/screens/selfie_verification_screen_test.dart
git commit -m "Add ApplicationSubmittedScreen and repoint Selfie Verification's Continue button to it"
```

---

### Task 4: Full-suite verification

**Files:** None (verification only).

**Interfaces:** None.

- [ ] **Step 1: Run the full test suite**

Run: `cd frontend && flutter test`
Expected: PASS, all tests green, no analyzer/compile errors from the earlier placeholder import in Task 1.

- [ ] **Step 2: Run static analysis**

Run: `cd frontend && flutter analyze`
Expected: No issues found (or only pre-existing issues unrelated to these changes).
