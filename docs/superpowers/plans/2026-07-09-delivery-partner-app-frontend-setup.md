# Delivery Partner App Frontend Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold the `frontend/` Flutter project for the Delivery Partner App: theme system, type-first core/models/providers/services/repositories layers (all backed by mock data), shared widget library, and all 17 feature folders — wired together end-to-end (Splash → placeholder routes) and verifiable with `flutter analyze` and a real run.

**Architecture:** Type-first layout — top-level `models/`, `providers/`, `services/`, `repositories/` each split into 15 per-domain subfolders; `features/<name>/` holds only `screens/` and `widgets/`. Riverpod (hand-written, no codegen) owns all state; GetX owns navigation only. Every mock repository implements an abstract interface so a real REST implementation can be swapped in later by changing one `Provider` line.

**Tech Stack:** Flutter (Dart >=3.4.0 <4.0.0), `flutter_riverpod`, `get`, `lucide_icons`, `google_fonts`, `shimmer`, `cached_network_image`, `lottie`, `pin_code_fields`, `flutter_svg`, `intl`, `equatable`, `flutter_animate`.

## Global Constraints

- Everything lives under `frontend/`. Do not create or reference a `backend/` folder.
- Package/app id: `com.qikzoo.deliverypartner`. Pubspec name: `delivery_partner_app`. Display name: "Qikzoo Partner".
- Platforms: Android + iOS only.
- State: Riverpod only, hand-written providers/notifiers, no `riverpod_generator`/`build_runner`.
- Navigation: GetX named routes only (`Get.toNamed`/`Get.offAllNamed`). Never `Navigator.push`. Never a GetX state controller.
- No `controllers/` folder anywhere — `TextEditingController`/`ScrollController`/`PageController` are created and disposed locally inside the widget that uses them.
- No hardcoded colors/spacing/radii — everything comes from `AppColors`/`AppSpacing`/`AppRadius`/`AppShadows`/`AppTypography` tokens defined in `core/theme/`.
- No `dio`/`http`, no `freezed`/`json_serializable` — hand-written models and a stub `ApiClient`.
- No test scaffolding, no localization/`intl` l10n wiring, no dark mode, no real screens beyond Splash — all deferred per the spec.
- Every repository is `abstract class XRepository` + `class MockXRepository implements XRepository`, exposed via `final xRepositoryProvider = Provider<XRepository>((ref) => MockXRepository());` — this is the only line a later backend swap touches.
- Verification throughout this plan uses `flutter analyze` (no test suite exists yet) since automated tests are explicitly out of scope for this pass.

Spec reference: `docs/superpowers/specs/2026-07-09-delivery-partner-app-frontend-setup-design.md`

---

### Task 1: Scaffold Flutter project & dependencies

**Files:**
- Create: `frontend/` (via `flutter create`)
- Modify: `frontend/pubspec.yaml`

**Interfaces:**
- Produces: a working `frontend/` Flutter project with all dependencies from Global Constraints installed, ready for `flutter analyze` to succeed on the default template.

- [ ] **Step 1: Create the Flutter project**

Run from the repo root (`d:/GROBIIT/Qikzoo Partner`):

```bash
flutter create --org com.qikzoo --project-name delivery_partner_app --platforms android,ios frontend
```

Expected: `frontend/` created with `lib/main.dart`, `pubspec.yaml`, `android/`, `ios/`.

- [ ] **Step 2: Replace pubspec.yaml dependencies**

Edit `frontend/pubspec.yaml` — replace the `dependencies:` and `dev_dependencies:` sections with:

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

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/illustrations/
    - assets/animations/
```

- [ ] **Step 3: Create asset folders**

```bash
mkdir -p frontend/assets/images frontend/assets/icons frontend/assets/illustrations frontend/assets/animations frontend/assets/fonts
```

Add an empty `.gitkeep` file to each so git tracks the empty directories:

```bash
touch frontend/assets/images/.gitkeep frontend/assets/icons/.gitkeep frontend/assets/illustrations/.gitkeep frontend/assets/animations/.gitkeep frontend/assets/fonts/.gitkeep
```

- [ ] **Step 4: Install dependencies**

Run: `cd frontend && flutter pub get`
Expected: `Got dependencies!` with no version resolution errors.

- [ ] **Step 5: Verify default template analyzes cleanly**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add frontend/
git commit -m "Scaffold Flutter project with locked dependency set"
```

---

### Task 2: Core theme tokens

**Files:**
- Create: `frontend/lib/core/theme/app_colors.dart`
- Create: `frontend/lib/core/theme/app_spacing.dart`
- Create: `frontend/lib/core/theme/app_radius.dart`
- Create: `frontend/lib/core/theme/app_shadows.dart`
- Create: `frontend/lib/core/theme/app_typography.dart`
- Create: `frontend/lib/core/theme/app_theme.dart`

**Interfaces:**
- Produces: `AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppTypography` static token classes, and `AppTheme.light` (a `ThemeData`) — consumed by every widget task from here on.

- [ ] **Step 1: Create `app_colors.dart`**

```dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1B2559);
  static const secondary = Color(0xFF2F6FED);
  static const accent = Color(0xFFFFB800);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFE4572E);
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);

  static final successBg = success.withOpacity(0.12);
  static final warningBg = warning.withOpacity(0.12);
  static final secondaryBg = secondary.withOpacity(0.12);
  static final accentBg = accent.withOpacity(0.14);
}
```

- [ ] **Step 2: Create `app_spacing.dart`**

```dart
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}
```

- [ ] **Step 3: Create `app_radius.dart`**

```dart
class AppRadius {
  AppRadius._();

  static const card = 18.0;
  static const button = 15.0;
  static const chip = 999.0;
  static const sheet = 24.0;
}
```

- [ ] **Step 4: Create `app_shadows.dart`**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F1B2559), offset: Offset(0, 8), blurRadius: 24),
    BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 12),
  ];

  static BoxDecoration glass({double opacity = 0.65}) => BoxDecoration(
        color: AppColors.surface.withOpacity(opacity),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      );
}
```

- [ ] **Step 5: Create `app_typography.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get h1 => GoogleFonts.manrope(
      fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle get h2 => GoogleFonts.manrope(
      fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle get body => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get bodyMedium => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle get caption => GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle get numericLg => GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: AppColors.primary);
  static TextStyle get numericMd => GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: AppColors.textPrimary);
}
```

- [ ] **Step 6: Create `app_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.warning,
        ),
        textTheme: TextTheme(
          headlineLarge: AppTypography.h1,
          headlineMedium: AppTypography.h2,
          bodyMedium: AppTypography.body,
          bodySmall: AppTypography.caption,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
        ),
      );
}
```

- [ ] **Step 7: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add frontend/lib/core/theme/
git commit -m "Add core theme token system"
```

---

### Task 3: Core error handling, network stub, constants, assets

**Files:**
- Create: `frontend/lib/core/error/failure.dart`
- Create: `frontend/lib/core/error/exceptions.dart`
- Create: `frontend/lib/core/error/result.dart`
- Create: `frontend/lib/core/network/api_client.dart`
- Create: `frontend/lib/core/constants/app_constants.dart`
- Create: `frontend/lib/core/assets/app_assets.dart`

**Interfaces:**
- Consumes: nothing from prior tasks.
- Produces: `Failure`, `AppException`, `Result<T>` (used by every mock repository from Task 15 onward), `ApiClient` stub (unused placeholder), `AppConstants`, `AppAssets`.

- [ ] **Step 1: Create `failure.dart`**

```dart
class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}
```

- [ ] **Step 2: Create `exceptions.dart`**

```dart
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error occurred']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found']);
}
```

- [ ] **Step 3: Create `result.dart`**

```dart
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(Failure failure) = ResultFailure<T>;

  bool get isSuccess => this is Success<T>;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class ResultFailure<T> extends Result<T> {
  final Failure failure;
  const ResultFailure(this.failure);
}
```

- [ ] **Step 4: Create `api_client.dart`**

```dart
/// Placeholder REST client. Not wired to anything yet — every repository
/// currently uses a Mock* implementation instead. When a real backend
/// exists, give this class real HTTP methods and swap the Provider bodies
/// in repositories/*/*_repository.dart from Mock* to a Rest* implementation
/// that depends on this client.
class ApiClient {
  final String baseUrl;

  const ApiClient({this.baseUrl = ''});
}
```

- [ ] **Step 5: Create `app_constants.dart`**

```dart
class AppConstants {
  AppConstants._();

  static const appName = 'Qikzoo Partner';
  static const mockNetworkDelay = Duration(milliseconds: 400);
  static const otpLength = 6;
  static const otpResendSeconds = 30;
}
```

- [ ] **Step 6: Create `app_assets.dart`**

```dart
class AppAssets {
  AppAssets._();

  static const imagesPath = 'assets/images';
  static const iconsPath = 'assets/icons';
  static const illustrationsPath = 'assets/illustrations';
  static const animationsPath = 'assets/animations';

  static const emptyStateIllustration = '$illustrationsPath/empty_state.svg';
  static const successAnimation = '$animationsPath/success.json';
}
```

- [ ] **Step 7: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add frontend/lib/core/error/ frontend/lib/core/network/ frontend/lib/core/constants/ frontend/lib/core/assets/
git commit -m "Add core error handling, network stub, constants, and asset paths"
```

---

### Task 4: Core validators, extensions, utils, helpers

**Files:**
- Create: `frontend/lib/core/validators/validators.dart`
- Create: `frontend/lib/core/extensions/context_extensions.dart`
- Create: `frontend/lib/core/extensions/datetime_extensions.dart`
- Create: `frontend/lib/core/utils/currency_formatter.dart`
- Create: `frontend/lib/core/helpers/date_helper.dart`

**Interfaces:**
- Produces: `Validators` (phone/OTP/email/IFSC/PAN/Aadhaar format checks — used by Task 13's onboarding models/forms and later screens), `context.spacing`-style extensions, `CurrencyFormatter.rupees`, `DateHelper.formatShort`.

- [ ] **Step 1: Create `validators.dart`**

```dart
class Validators {
  Validators._();

  static final _phoneRegex = RegExp(r'^[6-9]\d{9}$');
  static final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
  static final _ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  static final _panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  static final _aadhaarRegex = RegExp(r'^\d{12}$');

  static bool isValidPhone(String value) => _phoneRegex.hasMatch(value.trim());

  static bool isValidOtp(String value, {int length = 6}) =>
      RegExp('^\\d{$length}\$').hasMatch(value.trim());

  static bool isValidEmail(String value) => _emailRegex.hasMatch(value.trim());

  static bool isValidIfsc(String value) => _ifscRegex.hasMatch(value.trim().toUpperCase());

  static bool isValidPan(String value) => _panRegex.hasMatch(value.trim().toUpperCase());

  static bool isValidAadhaar(String value) => _aadhaarRegex.hasMatch(value.trim());
}
```

- [ ] **Step 2: Create `context_extensions.dart`**

```dart
import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
}
```

- [ ] **Step 3: Create `datetime_extensions.dart`**

```dart
extension DateTimeExtensions on DateTime {
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
```

- [ ] **Step 4: Create `currency_formatter.dart`**

```dart
class CurrencyFormatter {
  CurrencyFormatter._();

  static String rupees(num amount) => '₹${amount.toStringAsFixed(0)}';
}
```

- [ ] **Step 5: Create `date_helper.dart`**

```dart
class DateHelper {
  DateHelper._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String formatShort(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';
}
```

- [ ] **Step 6: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/core/validators/ frontend/lib/core/extensions/ frontend/lib/core/utils/ frontend/lib/core/helpers/
git commit -m "Add core validators, extensions, utils, and helpers"
```

---

### Task 5: Shared widgets — buttons

**Files:**
- Create: `frontend/lib/shared/widgets/buttons/primary_cta_button.dart`
- Create: `frontend/lib/shared/widgets/buttons/secondary_button.dart`
- Create: `frontend/lib/shared/widgets/buttons/outlined_button_custom.dart`
- Create: `frontend/lib/shared/widgets/buttons/icon_button_custom.dart`
- Create: `frontend/lib/shared/widgets/buttons/glass_button.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppRadius`, `AppSpacing`, `AppTypography`, `AppShadows` (Task 2).
- Produces: `PrimaryCtaButton`, `SecondaryButton`, `OutlinedButtonCustom`, `IconButtonCustom`, `GlassButton` — reused by every feature screen from Task 20 onward.

- [ ] **Step 1: Create `primary_cta_button.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class PrimaryCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;

  const PrimaryCtaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          disabledBackgroundColor: AppColors.accent.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `secondary_button.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create `outlined_button_custom.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class OutlinedButtonCustom extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const OutlinedButtonCustom({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create `icon_button_custom.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class IconButtonCustom extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  const IconButtonCustom({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Create `glass_button.dart`**

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';

class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const GlassButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: AppShadows.glass(),
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/shared/widgets/buttons/
git commit -m "Add shared button widgets"
```

---

### Task 6: Shared widgets — chips

**Files:**
- Create: `frontend/lib/shared/widgets/chips/status_chip.dart`
- Create: `frontend/lib/shared/widgets/chips/filter_chip_custom.dart`

**Interfaces:**
- Produces: `StatusChip(label, color, background)` (consumed by Task 8's `document_upload_card.dart`), `FilterChipCustom`.

- [ ] **Step 1: Create `status_chip.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const StatusChip({super.key, required this.label, required this.color, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `filter_chip_custom.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class FilterChipCustom extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterChipCustom({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.textSecondary.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/shared/widgets/chips/
git commit -m "Add shared chip widgets"
```

---

### Task 7: Shared widgets — inputs

**Files:**
- Create: `frontend/lib/shared/widgets/inputs/otp_field.dart`
- Create: `frontend/lib/shared/widgets/inputs/app_text_field.dart`
- Create: `frontend/lib/shared/widgets/inputs/app_dropdown.dart`
- Create: `frontend/lib/shared/widgets/inputs/search_bar_custom.dart`

**Interfaces:**
- Consumes: theme tokens (Task 2), `pin_code_fields` package (Task 1).
- Produces: `OtpField`, `AppTextField`, `AppDropdown<T>`, `SearchBarCustom`.

- [ ] **Step 1: Create `otp_field.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class OtpField extends StatelessWidget {
  final int length;
  final void Function(String) onCompleted;
  final void Function(String)? onChanged;

  const OtpField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      appContext: context,
      length: length,
      onCompleted: onCompleted,
      onChanged: onChanged ?? (_) {},
      keyboardType: TextInputType.number,
      animationType: AnimationType.fade,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(AppRadius.button),
        fieldHeight: 52,
        fieldWidth: 44,
        activeColor: AppColors.secondary,
        selectedColor: AppColors.secondary,
        inactiveColor: AppColors.textSecondary.withOpacity(0.3),
        activeFillColor: AppColors.surface,
        selectedFillColor: AppColors.surface,
        inactiveFillColor: AppColors.surface,
      ),
    );
  }
}
```

- [ ] **Step 2: Create `app_text_field.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? errorText;
  final bool obscureText;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: AppTypography.body,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create `app_dropdown.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      style: AppTypography.body,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(itemLabel(item))))
          .toList(),
      onChanged: onChanged,
    );
  }
}
```

- [ ] **Step 4: Create `search_bar_custom.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class SearchBarCustom extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final void Function(String)? onChanged;

  const SearchBarCustom({
    super.key,
    required this.controller,
    this.hint = 'Search',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.body,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/shared/widgets/inputs/
git commit -m "Add shared input widgets"
```

---

### Task 8: Shared widgets — cards

**Files:**
- Create: `frontend/lib/shared/widgets/cards/stat_card.dart`
- Create: `frontend/lib/shared/widgets/cards/order_card.dart`
- Create: `frontend/lib/shared/widgets/cards/document_upload_card.dart`
- Create: `frontend/lib/shared/widgets/cards/info_card.dart`

**Interfaces:**
- Consumes: theme tokens (Task 2), `StatusChip` (Task 6). Uses only primitive params (no model imports) — `DocumentUploadCard` takes plain `String`/`Color` params rather than importing `models/document_verification`, keeping `shared/` model-free per the dependency rule.
- Produces: `StatCard`, `OrderCard`, `DocumentUploadCard`, `InfoCard`.

- [ ] **Step 1: Create `stat_card.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const StatCard({super.key, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.numericMd),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create `order_card.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class OrderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              Text(amount, style: AppTypography.numericMd),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create `document_upload_card.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../chips/status_chip.dart';

class DocumentUploadCard extends StatelessWidget {
  final String documentLabel;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final String? rejectionReason;
  final VoidCallback? onTap;

  const DocumentUploadCard({
    super.key,
    required this.documentLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    this.rejectionReason,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(documentLabel, style: AppTypography.bodyMedium),
                  StatusChip(label: statusLabel, color: statusColor, background: statusBackground),
                ],
              ),
              if (rejectionReason != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(rejectionReason!,
                    style: AppTypography.caption.copyWith(color: AppColors.warning)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create `info_card.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const InfoCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/shared/widgets/cards/
git commit -m "Add shared card widgets"
```

---

### Task 9: Shared widgets — navigation

**Files:**
- Create: `frontend/lib/shared/widgets/navigation/floating_bottom_nav.dart`
- Create: `frontend/lib/shared/widgets/navigation/top_app_bar_custom.dart`
- Create: `frontend/lib/shared/widgets/navigation/step_progress_indicator.dart`
- Create: `frontend/lib/shared/widgets/navigation/section_header.dart`

**Interfaces:**
- Produces: `FloatingBottomNav(items, currentIndex, onTap)`, `TopAppBarCustom`, `StepProgressIndicator(totalSteps, currentStep)`, `SectionHeader`.

- [ ] **Step 1: Create `floating_bottom_nav.dart`**

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({required this.icon, required this.activeIcon, required this.label});
}

class FloatingBottomNav extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final void Function(int) onTap;

  const FloatingBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 64,
            decoration: AppShadows.glass().copyWith(boxShadow: AppShadows.card),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (index) {
                final isActive = index == currentIndex;
                final item = items[index];
                return GestureDetector(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                        size: 22,
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 2),
                        Text(item.label,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `top_app_bar_custom.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class TopAppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const TopAppBarCustom({super.key, required this.title, this.actions, this.leading});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: leading,
      title: Text(title, style: AppTypography.h2),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

- [ ] **Step 3: Create `step_progress_indicator.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class StepProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const StepProgressIndicator({super.key, required this.totalSteps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : AppSpacing.xs),
            height: 6,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.secondary : AppColors.textSecondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 4: Create `section_header.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.h2),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(actionLabel!,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.secondary)),
          ),
      ],
    );
  }
}
```

- [ ] **Step 5: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/shared/widgets/navigation/
git commit -m "Add shared navigation widgets"
```

---

### Task 10: Shared widgets — toggles

**Files:**
- Create: `frontend/lib/shared/widgets/toggles/online_offline_switch.dart`

**Interfaces:**
- Produces: `OnlineOfflineSwitch(isOnline, onChanged)` — consumed later by the Dashboard feature (post-plan) via `dashboardProvider`.

- [ ] **Step 1: Create `online_offline_switch.dart`**

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class OnlineOfflineSwitch extends StatelessWidget {
  final bool isOnline;
  final void Function(bool) onChanged;

  const OnlineOfflineSwitch({super.key, required this.isOnline, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isOnline),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: (isOnline ? AppColors.success : AppColors.textSecondary).withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: isOnline ? AppColors.success : AppColors.textSecondary.withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isOnline ? AppColors.success : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/shared/widgets/toggles/
git commit -m "Add shared Online/Offline toggle widget"
```

---

### Task 11: Shared widgets — dialogs

**Files:**
- Create: `frontend/lib/shared/widgets/dialogs/loading_dialog.dart`
- Create: `frontend/lib/shared/widgets/dialogs/confirmation_dialog.dart`
- Create: `frontend/lib/shared/widgets/dialogs/success_dialog.dart`
- Create: `frontend/lib/shared/widgets/dialogs/error_dialog.dart`

**Interfaces:**
- Produces: `LoadingDialog.show(context)`, `ConfirmationDialog.show(context, {title, message})`, `SuccessDialog.show(context, {message})`, `ErrorDialog.show(context, {message})` — static helpers wrapping `showDialog`.

- [ ] **Step 1: Create `loading_dialog.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class LoadingDialog {
  LoadingDialog._();

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `confirmation_dialog.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../buttons/primary_cta_button.dart';
import '../buttons/outlined_button_custom.dart';

class ConfirmationDialog {
  ConfirmationDialog._();

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: AppTypography.body, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButtonCustom(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryCtaButton(
                      label: 'Confirm',
                      onPressed: () => Navigator.of(ctx).pop(true),
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
}
```

- [ ] **Step 3: Create `success_dialog.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class SuccessDialog {
  SuccessDialog._();

  static Future<void> show(BuildContext context, {required String message}) {
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 48),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: AppTypography.body, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create `error_dialog.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class ErrorDialog {
  ErrorDialog._();

  static Future<void> show(BuildContext context, {required String message}) {
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertTriangle, color: AppColors.warning, size: 48),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: AppTypography.body, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/shared/widgets/dialogs/
git commit -m "Add shared dialog widgets"
```

---

### Task 12: Shared widgets — misc

**Files:**
- Create: `frontend/lib/shared/widgets/misc/empty_state.dart`
- Create: `frontend/lib/shared/widgets/misc/loading_skeleton.dart`
- Create: `frontend/lib/shared/widgets/misc/error_widget_custom.dart`
- Create: `frontend/lib/shared/widgets/misc/countdown_timer.dart`
- Create: `frontend/lib/shared/widgets/misc/earnings_breakdown_widget.dart`
- Create: `frontend/lib/shared/widgets/misc/rating_stars.dart`
- Create: `frontend/lib/shared/widgets/misc/cached_avatar.dart`

**Interfaces:**
- Produces: `EmptyState`, `LoadingSkeleton`, `ErrorWidgetCustom`, `CountdownTimer(seconds, onExpired)`, `EarningsBreakdownWidget(base, distance, surge, tip)`, `RatingStars(rating)`, `CachedAvatar(url)`.

- [ ] **Step 1: Create `empty_state.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, this.icon = LucideIcons.inbox, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppTypography.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create `loading_skeleton.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class LoadingSkeleton extends StatelessWidget {
  final double height;
  final double? width;

  const LoadingSkeleton({super.key, this.height = 16, this.width});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.textSecondary.withOpacity(0.15),
      highlightColor: AppColors.textSecondary.withOpacity(0.05),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create `error_widget_custom.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../buttons/secondary_button.dart';

class ErrorWidgetCustom extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorWidgetCustom({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.alertCircle, size: 40, color: AppColors.warning),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppTypography.body, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(width: 140, child: SecondaryButton(label: 'Retry', onPressed: onRetry)),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Create `countdown_timer.dart`**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class CountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onExpired;

  const CountdownTimer({super.key, required this.seconds, required this.onExpired});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int _remaining = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        widget.onExpired();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '00:${_remaining.toString().padLeft(2, '0')}',
      style: AppTypography.numericMd.copyWith(color: AppColors.warning),
    );
  }
}
```

- [ ] **Step 5: Create `earnings_breakdown_widget.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class EarningsBreakdownWidget extends StatelessWidget {
  final double base;
  final double distance;
  final double surge;
  final double tip;

  const EarningsBreakdownWidget({
    super.key,
    required this.base,
    required this.distance,
    required this.surge,
    required this.tip,
  });

  double get total => base + distance + surge + tip;

  Widget _row(String label, double value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.body),
            Text(CurrencyFormatter.rupees(value), style: AppTypography.bodyMedium),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row('Base fare', base),
        _row('Distance', distance),
        _row('Surge', surge),
        _row('Tip', tip),
        const Divider(color: AppColors.background, height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: AppTypography.h2),
            Text(CurrencyFormatter.rupees(total), style: AppTypography.numericMd),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 6: Create `rating_stars.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const RatingStars({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < fullStars ? LucideIcons.star : LucideIcons.star,
          size: size,
          color: index < fullStars ? AppColors.accent : AppColors.textSecondary.withOpacity(0.3),
        );
      }),
    );
  }
}
```

- [ ] **Step 7: Create `cached_avatar.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

class CachedAvatar extends StatelessWidget {
  final String? url;
  final double radius;

  const CachedAvatar({super.key, this.url, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.secondaryBg,
        child: Icon(LucideIcons.user, color: AppColors.secondary, size: radius),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_, __) => CircleAvatar(radius: radius, backgroundColor: AppColors.secondaryBg),
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.secondaryBg,
          child: Icon(LucideIcons.user, color: AppColors.secondary, size: radius),
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add frontend/lib/shared/widgets/misc/
git commit -m "Add shared misc widgets"
```

---

### Task 13: Models — onboarding domains

**Files:**
- Create: `frontend/lib/models/authentication/otp_model.dart`
- Create: `frontend/lib/models/authentication/auth_session_model.dart`
- Create: `frontend/lib/models/partner_registration/personal_info_model.dart`
- Create: `frontend/lib/models/partner_registration/vehicle_model.dart`
- Create: `frontend/lib/models/partner_registration/delivery_zone_model.dart`
- Create: `frontend/lib/models/document_verification/document_model.dart`
- Create: `frontend/lib/models/bank_details/bank_details_model.dart`
- Create: `frontend/lib/models/verification_status/verification_step_model.dart`
- Create: `frontend/lib/models/training/training_module_model.dart`
- Create: `frontend/lib/models/agreement/agreement_model.dart`
- Create: `frontend/lib/models/approval/approval_status_model.dart`

**Interfaces:**
- Consumes: `equatable` package (Task 1).
- Produces: `OtpModel`, `AuthSessionModel`, `PersonalInfoModel`, `VehicleType` enum + `VehicleModel`, `DeliveryZoneModel`, `DocumentType`/`DocumentStatus` enums + `DocumentModel`, `BankDetailsModel`, `VerificationStepType`/`VerificationStepState` enums + `VerificationStepModel`, `TrainingModuleModel`, `AgreementModel`, `ApprovalState` enum + `ApprovalStatusModel` — consumed by Task 15 (repositories) and Task 17 (providers) for this same domain group.

- [ ] **Step 1: Create `otp_model.dart`**

```dart
import 'package:equatable/equatable.dart';

class OtpModel extends Equatable {
  final String phoneNumber;
  final bool isVerified;
  final DateTime expiresAt;

  const OtpModel({required this.phoneNumber, required this.isVerified, required this.expiresAt});

  OtpModel copyWith({String? phoneNumber, bool? isVerified, DateTime? expiresAt}) => OtpModel(
        phoneNumber: phoneNumber ?? this.phoneNumber,
        isVerified: isVerified ?? this.isVerified,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  @override
  List<Object?> get props => [phoneNumber, isVerified, expiresAt];
}
```

- [ ] **Step 2: Create `auth_session_model.dart`**

```dart
import 'package:equatable/equatable.dart';

class AuthSessionModel extends Equatable {
  final String partnerId;
  final String token;
  final bool isAuthenticated;

  const AuthSessionModel({
    required this.partnerId,
    required this.token,
    required this.isAuthenticated,
  });

  static const empty = AuthSessionModel(partnerId: '', token: '', isAuthenticated: false);

  @override
  List<Object?> get props => [partnerId, token, isAuthenticated];
}
```

- [ ] **Step 3: Create `personal_info_model.dart`**

```dart
import 'package:equatable/equatable.dart';

enum Gender { male, female, other }

class PersonalInfoModel extends Equatable {
  final String fullName;
  final DateTime dateOfBirth;
  final Gender gender;
  final String? email;
  final String emergencyContact;
  final String? referralCode;

  const PersonalInfoModel({
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.email,
    required this.emergencyContact,
    this.referralCode,
  });

  @override
  List<Object?> get props =>
      [fullName, dateOfBirth, gender, email, emergencyContact, referralCode];
}
```

- [ ] **Step 4: Create `vehicle_model.dart`**

```dart
import 'package:equatable/equatable.dart';

enum VehicleType { bike, scooter, bicycle, electricVehicle }

class VehicleModel extends Equatable {
  final VehicleType type;
  final String? registrationNumber;

  const VehicleModel({required this.type, this.registrationNumber});

  @override
  List<Object?> get props => [type, registrationNumber];
}
```

- [ ] **Step 5: Create `delivery_zone_model.dart`**

```dart
import 'package:equatable/equatable.dart';

class DeliveryZoneModel extends Equatable {
  final String state;
  final String city;
  final String preferredZone;

  const DeliveryZoneModel({required this.state, required this.city, required this.preferredZone});

  @override
  List<Object?> get props => [state, city, preferredZone];
}
```

- [ ] **Step 6: Create `document_model.dart`**

```dart
import 'package:equatable/equatable.dart';

enum DocumentType {
  profilePhoto,
  aadhaar,
  pan,
  drivingLicense,
  vehicleRc,
  vehicleInsurance,
  vehiclePhoto,
  bankProof,
}

enum DocumentStatus { notUploaded, uploading, pendingVerification, verified, rejected }

class DocumentModel extends Equatable {
  final DocumentType type;
  final DocumentStatus status;
  final String? fileUrl;
  final String? rejectionReason;

  const DocumentModel({
    required this.type,
    required this.status,
    this.fileUrl,
    this.rejectionReason,
  });

  DocumentModel copyWith({DocumentStatus? status, String? fileUrl, String? rejectionReason}) =>
      DocumentModel(
        type: type,
        status: status ?? this.status,
        fileUrl: fileUrl ?? this.fileUrl,
        rejectionReason: rejectionReason ?? this.rejectionReason,
      );

  @override
  List<Object?> get props => [type, status, fileUrl, rejectionReason];
}
```

- [ ] **Step 7: Create `bank_details_model.dart`**

```dart
import 'package:equatable/equatable.dart';

class BankDetailsModel extends Equatable {
  final String accountHolderName;
  final String accountNumber;
  final String ifsc;
  final String? upiId;

  const BankDetailsModel({
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifsc,
    this.upiId,
  });

  @override
  List<Object?> get props => [accountHolderName, accountNumber, ifsc, upiId];
}
```

- [ ] **Step 8: Create `verification_step_model.dart`**

```dart
import 'package:equatable/equatable.dart';

enum VerificationStepType { identity, vehicle, bank, training, finalApproval }

enum VerificationStepState { pending, inProgress, completed }

class VerificationStepModel extends Equatable {
  final VerificationStepType step;
  final VerificationStepState state;

  const VerificationStepModel({required this.step, required this.state});

  @override
  List<Object?> get props => [step, state];
}
```

- [ ] **Step 9: Create `training_module_model.dart`**

```dart
import 'package:equatable/equatable.dart';

class TrainingModuleModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final bool isCompleted;

  const TrainingModuleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.isCompleted,
  });

  TrainingModuleModel copyWith({bool? isCompleted}) => TrainingModuleModel(
        id: id,
        title: title,
        description: description,
        durationMinutes: durationMinutes,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  @override
  List<Object?> get props => [id, title, description, durationMinutes, isCompleted];
}
```

- [ ] **Step 10: Create `agreement_model.dart`**

```dart
import 'package:equatable/equatable.dart';

class AgreementModel extends Equatable {
  final bool termsAccepted;
  final bool privacyAccepted;
  final bool partnerAgreementAccepted;
  final DateTime? acceptedAt;

  const AgreementModel({
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.partnerAgreementAccepted,
    this.acceptedAt,
  });

  bool get allAccepted => termsAccepted && privacyAccepted && partnerAgreementAccepted;

  @override
  List<Object?> get props =>
      [termsAccepted, privacyAccepted, partnerAgreementAccepted, acceptedAt];
}
```

- [ ] **Step 11: Create `approval_status_model.dart`**

```dart
import 'package:equatable/equatable.dart';

enum ApprovalState { pending, underReview, approved, rejected }

class ApprovalStatusModel extends Equatable {
  final ApprovalState state;
  final String? rejectionReason;

  const ApprovalStatusModel({required this.state, this.rejectionReason});

  @override
  List<Object?> get props => [state, rejectionReason];
}
```

- [ ] **Step 12: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 13: Commit**

```bash
git add frontend/lib/models/authentication/ frontend/lib/models/partner_registration/ frontend/lib/models/document_verification/ frontend/lib/models/bank_details/ frontend/lib/models/verification_status/ frontend/lib/models/training/ frontend/lib/models/agreement/ frontend/lib/models/approval/
git commit -m "Add onboarding domain models"
```

---

### Task 14: Models — operational domains

**Files:**
- Create: `frontend/lib/models/dashboard/dashboard_stats_model.dart`
- Create: `frontend/lib/models/orders/order_model.dart`
- Create: `frontend/lib/models/orders/earnings_breakdown_model.dart`
- Create: `frontend/lib/models/wallet/wallet_model.dart`
- Create: `frontend/lib/models/wallet/transaction_model.dart`
- Create: `frontend/lib/models/support/support_ticket_model.dart`
- Create: `frontend/lib/models/profile/partner_profile_model.dart`
- Create: `frontend/lib/models/profile/rating_model.dart`
- Create: `frontend/lib/models/notifications/notification_model.dart`
- Create: `frontend/lib/models/settings/app_settings_model.dart`

**Interfaces:**
- Consumes: `equatable` package (Task 1).
- Produces: `DashboardStatsModel`, `OrderStatus` enum + `OrderModel`, `EarningsBreakdownModel`, `WalletModel`, `TransactionType` enum + `TransactionModel`, `SupportTicketStatus` enum + `SupportTicketModel`, `PartnerProfileModel`, `RatingModel`, `NotificationModel`, `AppSettingsModel` — consumed by Task 16 (repositories) and Task 18 (providers) for this same domain group.

- [ ] **Step 1: Create `dashboard_stats_model.dart`**

```dart
import 'package:equatable/equatable.dart';

class DashboardStatsModel extends Equatable {
  final bool isOnline;
  final double todaysEarnings;
  final double walletBalance;
  final int activeIncentives;
  final double acceptanceRate;
  final double rating;
  final int completedOrders;

  const DashboardStatsModel({
    required this.isOnline,
    required this.todaysEarnings,
    required this.walletBalance,
    required this.activeIncentives,
    required this.acceptanceRate,
    required this.rating,
    required this.completedOrders,
  });

  DashboardStatsModel copyWith({bool? isOnline}) => DashboardStatsModel(
        isOnline: isOnline ?? this.isOnline,
        todaysEarnings: todaysEarnings,
        walletBalance: walletBalance,
        activeIncentives: activeIncentives,
        acceptanceRate: acceptanceRate,
        rating: rating,
        completedOrders: completedOrders,
      );

  @override
  List<Object?> get props => [
        isOnline,
        todaysEarnings,
        walletBalance,
        activeIncentives,
        acceptanceRate,
        rating,
        completedOrders,
      ];
}
```

- [ ] **Step 2: Create `order_model.dart`**

```dart
import 'package:equatable/equatable.dart';

enum OrderStatus {
  waitingForOrders,
  incomingRequest,
  accepted,
  navigatingToRestaurant,
  arrivedAtRestaurant,
  pickupConfirmed,
  navigatingToCustomer,
  arrivedAtCustomer,
  deliveryConfirmed,
  completed,
}

class OrderModel extends Equatable {
  final String id;
  final String restaurantName;
  final String customerName;
  final String pickupAddress;
  final String dropAddress;
  final OrderStatus status;
  final double amount;
  final double distanceKm;

  const OrderModel({
    required this.id,
    required this.restaurantName,
    required this.customerName,
    required this.pickupAddress,
    required this.dropAddress,
    required this.status,
    required this.amount,
    required this.distanceKm,
  });

  OrderModel copyWith({OrderStatus? status}) => OrderModel(
        id: id,
        restaurantName: restaurantName,
        customerName: customerName,
        pickupAddress: pickupAddress,
        dropAddress: dropAddress,
        status: status ?? this.status,
        amount: amount,
        distanceKm: distanceKm,
      );

  @override
  List<Object?> get props =>
      [id, restaurantName, customerName, pickupAddress, dropAddress, status, amount, distanceKm];
}
```

- [ ] **Step 3: Create `earnings_breakdown_model.dart`**

```dart
import 'package:equatable/equatable.dart';

class EarningsBreakdownModel extends Equatable {
  final String orderId;
  final double base;
  final double distance;
  final double surge;
  final double tip;

  const EarningsBreakdownModel({
    required this.orderId,
    required this.base,
    required this.distance,
    required this.surge,
    required this.tip,
  });

  double get total => base + distance + surge + tip;

  @override
  List<Object?> get props => [orderId, base, distance, surge, tip];
}
```

- [ ] **Step 4: Create `wallet_model.dart`**

```dart
import 'package:equatable/equatable.dart';

class WalletModel extends Equatable {
  final double balance;
  final double pendingAmount;

  const WalletModel({required this.balance, required this.pendingAmount});

  @override
  List<Object?> get props => [balance, pendingAmount];
}
```

- [ ] **Step 5: Create `transaction_model.dart`**

```dart
import 'package:equatable/equatable.dart';

enum TransactionType { credit, debit }

class TransactionModel extends Equatable {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime date;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });

  @override
  List<Object?> get props => [id, type, amount, description, date];
}
```

- [ ] **Step 6: Create `support_ticket_model.dart`**

```dart
import 'package:equatable/equatable.dart';

enum SupportTicketStatus { open, inProgress, resolved }

class SupportTicketModel extends Equatable {
  final String id;
  final String subject;
  final SupportTicketStatus status;
  final DateTime createdAt;

  const SupportTicketModel({
    required this.id,
    required this.subject,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, subject, status, createdAt];
}
```

- [ ] **Step 7: Create `partner_profile_model.dart`**

```dart
import 'package:equatable/equatable.dart';

class PartnerProfileModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final String vehicleType;
  final DateTime joinedDate;

  const PartnerProfileModel({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
    required this.vehicleType,
    required this.joinedDate,
  });

  @override
  List<Object?> get props => [id, name, phone, photoUrl, vehicleType, joinedDate];
}
```

- [ ] **Step 8: Create `rating_model.dart`**

```dart
import 'package:equatable/equatable.dart';

class RatingModel extends Equatable {
  final double average;
  final int totalRatings;

  const RatingModel({required this.average, required this.totalRatings});

  @override
  List<Object?> get props => [average, totalRatings];
}
```

- [ ] **Step 9: Create `notification_model.dart`**

```dart
import 'package:equatable/equatable.dart';

enum NotificationType { order, earnings, system, promotion }

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final NotificationType type;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.type,
  });

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        type: type,
      );

  @override
  List<Object?> get props => [id, title, body, isRead, createdAt, type];
}
```

- [ ] **Step 10: Create `app_settings_model.dart`**

```dart
import 'package:equatable/equatable.dart';

class AppSettingsModel extends Equatable {
  final bool notificationsEnabled;
  final String language;

  const AppSettingsModel({required this.notificationsEnabled, required this.language});

  static const defaults = AppSettingsModel(notificationsEnabled: true, language: 'en');

  AppSettingsModel copyWith({bool? notificationsEnabled, String? language}) => AppSettingsModel(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        language: language ?? this.language,
      );

  @override
  List<Object?> get props => [notificationsEnabled, language];
}
```

- [ ] **Step 11: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 12: Commit**

```bash
git add frontend/lib/models/dashboard/ frontend/lib/models/orders/ frontend/lib/models/wallet/ frontend/lib/models/support/ frontend/lib/models/profile/ frontend/lib/models/notifications/ frontend/lib/models/settings/
git commit -m "Add operational domain models"
```

---

### Task 15: Repositories & services — onboarding domains

**Files:**
- Create: `frontend/lib/repositories/authentication/auth_repository.dart`
- Create: `frontend/lib/repositories/partner_registration/partner_registration_repository.dart`
- Create: `frontend/lib/repositories/document_verification/document_repository.dart`
- Create: `frontend/lib/repositories/bank_details/bank_details_repository.dart`
- Create: `frontend/lib/repositories/verification_status/verification_status_repository.dart`
- Create: `frontend/lib/repositories/training/training_repository.dart`
- Create: `frontend/lib/repositories/agreement/agreement_repository.dart`
- Create: `frontend/lib/repositories/approval/approval_repository.dart`

**Interfaces:**
- Consumes: models from Task 13, `AppConstants.mockNetworkDelay` (Task 3).
- Produces: `authRepositoryProvider`, `partnerRegistrationRepositoryProvider`, `documentRepositoryProvider`, `bankDetailsRepositoryProvider`, `verificationStatusRepositoryProvider`, `trainingRepositoryProvider`, `agreementRepositoryProvider`, `approvalRepositoryProvider` — each a `Provider<XRepository>` consumed by Task 17's providers.

- [ ] **Step 1: Create `auth_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/authentication/otp_model.dart';
import '../../models/authentication/auth_session_model.dart';

abstract class AuthRepository {
  Future<OtpModel> requestOtp(String phoneNumber);
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp);
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<OtpModel> requestOtp(String phoneNumber) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return OtpModel(
      phoneNumber: phoneNumber,
      isVerified: false,
      expiresAt: DateTime.now().add(const Duration(seconds: AppConstants.otpResendSeconds)),
    );
  }

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return AuthSessionModel(
      partnerId: 'partner_mock_001',
      token: 'mock_token_abc123',
      isAuthenticated: true,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => MockAuthRepository());
```

- [ ] **Step 2: Create `partner_registration_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/partner_registration/personal_info_model.dart';
import '../../models/partner_registration/vehicle_model.dart';
import '../../models/partner_registration/delivery_zone_model.dart';

abstract class PartnerRegistrationRepository {
  Future<void> savePersonalInfo(PersonalInfoModel info);
  Future<void> saveVehicle(VehicleModel vehicle);
  Future<void> saveDeliveryZone(DeliveryZoneModel zone);
}

class MockPartnerRegistrationRepository implements PartnerRegistrationRepository {
  @override
  Future<void> savePersonalInfo(PersonalInfoModel info) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
  }

  @override
  Future<void> saveVehicle(VehicleModel vehicle) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
  }

  @override
  Future<void> saveDeliveryZone(DeliveryZoneModel zone) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
  }
}

final partnerRegistrationRepositoryProvider =
    Provider<PartnerRegistrationRepository>((ref) => MockPartnerRegistrationRepository());
```

- [ ] **Step 3: Create `document_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/document_verification/document_model.dart';

abstract class DocumentRepository {
  Future<List<DocumentModel>> getDocuments();
  Future<DocumentModel> uploadDocument(DocumentType type, String filePath);
}

class MockDocumentRepository implements DocumentRepository {
  @override
  Future<List<DocumentModel>> getDocuments() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return DocumentType.values
        .map((type) => DocumentModel(type: type, status: DocumentStatus.notUploaded))
        .toList();
  }

  @override
  Future<DocumentModel> uploadDocument(DocumentType type, String filePath) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return DocumentModel(
      type: type,
      status: DocumentStatus.pendingVerification,
      fileUrl: filePath,
    );
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) => MockDocumentRepository());
```

- [ ] **Step 4: Create `bank_details_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/bank_details/bank_details_model.dart';

abstract class BankDetailsRepository {
  Future<void> saveBankDetails(BankDetailsModel details);
  Future<BankDetailsModel?> getBankDetails();
}

class MockBankDetailsRepository implements BankDetailsRepository {
  BankDetailsModel? _stored;

  @override
  Future<void> saveBankDetails(BankDetailsModel details) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    _stored = details;
  }

  @override
  Future<BankDetailsModel?> getBankDetails() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return _stored;
  }
}

final bankDetailsRepositoryProvider =
    Provider<BankDetailsRepository>((ref) => MockBankDetailsRepository());
```

- [ ] **Step 5: Create `verification_status_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/verification_status/verification_step_model.dart';

abstract class VerificationStatusRepository {
  Future<List<VerificationStepModel>> getSteps();
}

class MockVerificationStatusRepository implements VerificationStatusRepository {
  @override
  Future<List<VerificationStepModel>> getSteps() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return const [
      VerificationStepModel(step: VerificationStepType.identity, state: VerificationStepState.completed),
      VerificationStepModel(step: VerificationStepType.vehicle, state: VerificationStepState.completed),
      VerificationStepModel(step: VerificationStepType.bank, state: VerificationStepState.inProgress),
      VerificationStepModel(step: VerificationStepType.training, state: VerificationStepState.pending),
      VerificationStepModel(step: VerificationStepType.finalApproval, state: VerificationStepState.pending),
    ];
  }
}

final verificationStatusRepositoryProvider =
    Provider<VerificationStatusRepository>((ref) => MockVerificationStatusRepository());
```

- [ ] **Step 6: Create `training_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/training/training_module_model.dart';

abstract class TrainingRepository {
  Future<List<TrainingModuleModel>> getModules();
  Future<void> markCompleted(String moduleId);
}

class MockTrainingRepository implements TrainingRepository {
  final List<TrainingModuleModel> _modules = const [
    TrainingModuleModel(id: 'm1', title: 'Pickup Process', description: 'How to pick up orders', durationMinutes: 5, isCompleted: false),
    TrainingModuleModel(id: 'm2', title: 'Customer Interaction', description: 'Talking to customers', durationMinutes: 4, isCompleted: false),
    TrainingModuleModel(id: 'm3', title: 'Safety', description: 'Road and delivery safety', durationMinutes: 6, isCompleted: false),
    TrainingModuleModel(id: 'm4', title: 'Cash Orders', description: 'Handling cash payments', durationMinutes: 3, isCompleted: false),
    TrainingModuleModel(id: 'm5', title: 'Emergency Support', description: 'What to do in an emergency', durationMinutes: 4, isCompleted: false),
    TrainingModuleModel(id: 'm6', title: 'Delivery Guidelines', description: 'General delivery guidelines', durationMinutes: 5, isCompleted: false),
  ];

  @override
  Future<List<TrainingModuleModel>> getModules() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return _modules;
  }

  @override
  Future<void> markCompleted(String moduleId) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
  }
}

final trainingRepositoryProvider = Provider<TrainingRepository>((ref) => MockTrainingRepository());
```

- [ ] **Step 7: Create `agreement_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/agreement/agreement_model.dart';

abstract class AgreementRepository {
  Future<void> acceptAgreement(AgreementModel agreement);
}

class MockAgreementRepository implements AgreementRepository {
  @override
  Future<void> acceptAgreement(AgreementModel agreement) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
  }
}

final agreementRepositoryProvider = Provider<AgreementRepository>((ref) => MockAgreementRepository());
```

- [ ] **Step 8: Create `approval_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/approval/approval_status_model.dart';

abstract class ApprovalRepository {
  Future<ApprovalStatusModel> getApprovalStatus();
}

class MockApprovalRepository implements ApprovalRepository {
  @override
  Future<ApprovalStatusModel> getApprovalStatus() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return const ApprovalStatusModel(state: ApprovalState.underReview);
  }
}

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) => MockApprovalRepository());
```

- [ ] **Step 9: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
git add frontend/lib/repositories/authentication/ frontend/lib/repositories/partner_registration/ frontend/lib/repositories/document_verification/ frontend/lib/repositories/bank_details/ frontend/lib/repositories/verification_status/ frontend/lib/repositories/training/ frontend/lib/repositories/agreement/ frontend/lib/repositories/approval/
git commit -m "Add onboarding domain mock repositories"
```

*(Note: this app's spec has no separate `services/` layer distinct from repositories for onboarding — mock latency/data generation lives directly in each `MockXRepository`, matching the swap-point pattern in the design doc. The `services/` folders from the original spec are populated in Task 16 for the two operational domains — orders and notifications — where a mock "service" naturally differs from a "repository" (simulated live order-stream push vs. CRUD-style fetch).)*

---

### Task 16: Repositories & services — operational domains

**Files:**
- Create: `frontend/lib/repositories/dashboard/dashboard_repository.dart`
- Create: `frontend/lib/repositories/orders/orders_repository.dart`
- Create: `frontend/lib/services/orders/order_stream_service.dart`
- Create: `frontend/lib/repositories/wallet/wallet_repository.dart`
- Create: `frontend/lib/repositories/support/support_repository.dart`
- Create: `frontend/lib/repositories/profile/profile_repository.dart`
- Create: `frontend/lib/repositories/notifications/notifications_repository.dart`
- Create: `frontend/lib/repositories/settings/settings_repository.dart`

**Interfaces:**
- Consumes: models from Task 14, `AppConstants.mockNetworkDelay` (Task 3).
- Produces: `dashboardRepositoryProvider`, `ordersRepositoryProvider`, `orderStreamServiceProvider`, `walletRepositoryProvider`, `supportRepositoryProvider`, `profileRepositoryProvider`, `notificationsRepositoryProvider`, `settingsRepositoryProvider` — consumed by Task 18's providers.

- [ ] **Step 1: Create `dashboard_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/dashboard/dashboard_stats_model.dart';

abstract class DashboardRepository {
  Future<DashboardStatsModel> getStats();
  Future<DashboardStatsModel> setOnline(bool isOnline);
}

class MockDashboardRepository implements DashboardRepository {
  bool _isOnline = false;

  @override
  Future<DashboardStatsModel> getStats() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return DashboardStatsModel(
      isOnline: _isOnline,
      todaysEarnings: 842,
      walletBalance: 3120,
      activeIncentives: 2,
      acceptanceRate: 0.92,
      rating: 4.7,
      completedOrders: 14,
    );
  }

  @override
  Future<DashboardStatsModel> setOnline(bool isOnline) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    _isOnline = isOnline;
    return getStats();
  }
}

final dashboardRepositoryProvider =
    Provider<DashboardRepository>((ref) => MockDashboardRepository());
```

- [ ] **Step 2: Create `orders_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/orders/order_model.dart';

abstract class OrdersRepository {
  Future<OrderModel?> getActiveOrder();
  Future<OrderModel> updateOrderStatus(String orderId, OrderStatus status);
  Future<List<OrderModel>> getOrderHistory();
}

class MockOrdersRepository implements OrdersRepository {
  OrderModel? _active;

  @override
  Future<OrderModel?> getActiveOrder() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return _active;
  }

  @override
  Future<OrderModel> updateOrderStatus(String orderId, OrderStatus status) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    _active = (_active ?? _mockOrder(orderId)).copyWith(status: status);
    return _active!;
  }

  @override
  Future<List<OrderModel>> getOrderHistory() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return [_mockOrder('order_1').copyWith(status: OrderStatus.completed)];
  }

  OrderModel _mockOrder(String id) => OrderModel(
        id: id,
        restaurantName: 'Spice Route Kitchen',
        customerName: 'Aditi Sharma',
        pickupAddress: '12 MG Road',
        dropAddress: '45 Park Street',
        status: OrderStatus.incomingRequest,
        amount: 96,
        distanceKm: 3.2,
      );
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) => MockOrdersRepository());
```

- [ ] **Step 3: Create `order_stream_service.dart`**

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/orders/order_model.dart';

/// Simulates a live incoming-order push feed. A real backend later replaces
/// this with a websocket/FCM-backed stream behind the same Stream<OrderModel> shape.
class OrderStreamService {
  Stream<OrderModel> incomingOrders() async* {
    await Future.delayed(const Duration(seconds: 5));
    yield const OrderModel(
      id: 'order_incoming_1',
      restaurantName: 'Green Bowl Cafe',
      customerName: 'Rohan Mehta',
      pickupAddress: '9 Residency Road',
      dropAddress: '21 Church Street',
      status: OrderStatus.incomingRequest,
      amount: 78,
      distanceKm: 2.1,
    );
  }
}

final orderStreamServiceProvider = Provider<OrderStreamService>((ref) => OrderStreamService());
```

- [ ] **Step 4: Create `wallet_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/wallet/wallet_model.dart';
import '../../models/wallet/transaction_model.dart';

abstract class WalletRepository {
  Future<WalletModel> getWallet();
  Future<List<TransactionModel>> getTransactions();
}

class MockWalletRepository implements WalletRepository {
  @override
  Future<WalletModel> getWallet() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return const WalletModel(balance: 3120, pendingAmount: 240);
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return [
      TransactionModel(
        id: 'txn_1',
        type: TransactionType.credit,
        amount: 96,
        description: 'Order #order_1 payout',
        date: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) => MockWalletRepository());
```

- [ ] **Step 5: Create `support_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/support/support_ticket_model.dart';

abstract class SupportRepository {
  Future<List<SupportTicketModel>> getTickets();
  Future<SupportTicketModel> createTicket(String subject);
}

class MockSupportRepository implements SupportRepository {
  final List<SupportTicketModel> _tickets = [];

  @override
  Future<List<SupportTicketModel>> getTickets() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return _tickets;
  }

  @override
  Future<SupportTicketModel> createTicket(String subject) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    final ticket = SupportTicketModel(
      id: 'ticket_${_tickets.length + 1}',
      subject: subject,
      status: SupportTicketStatus.open,
      createdAt: DateTime.now(),
    );
    _tickets.add(ticket);
    return ticket;
  }
}

final supportRepositoryProvider = Provider<SupportRepository>((ref) => MockSupportRepository());
```

- [ ] **Step 6: Create `profile_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/profile/partner_profile_model.dart';
import '../../models/profile/rating_model.dart';

abstract class ProfileRepository {
  Future<PartnerProfileModel> getProfile();
  Future<RatingModel> getRating();
}

class MockProfileRepository implements ProfileRepository {
  @override
  Future<PartnerProfileModel> getProfile() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return PartnerProfileModel(
      id: 'partner_mock_001',
      name: 'Ankit Verma',
      phone: '9876543210',
      vehicleType: 'Bike',
      joinedDate: DateTime(2026, 3, 12),
    );
  }

  @override
  Future<RatingModel> getRating() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return const RatingModel(average: 4.7, totalRatings: 212);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => MockProfileRepository());
```

- [ ] **Step 7: Create `notifications_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/notifications/notification_model.dart';

abstract class NotificationsRepository {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
}

class MockNotificationsRepository implements NotificationsRepository {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: 'n1',
      title: 'New incentive available',
      body: 'Complete 5 more orders today to earn a bonus.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      type: NotificationType.promotion,
    ),
  ];

  @override
  Future<List<NotificationModel>> getNotifications() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return _notifications;
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }
}

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) => MockNotificationsRepository());
```

- [ ] **Step 8: Create `settings_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/settings/app_settings_model.dart';

abstract class SettingsRepository {
  Future<AppSettingsModel> getSettings();
  Future<AppSettingsModel> updateSettings(AppSettingsModel settings);
}

class MockSettingsRepository implements SettingsRepository {
  AppSettingsModel _settings = AppSettingsModel.defaults;

  @override
  Future<AppSettingsModel> getSettings() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return _settings;
  }

  @override
  Future<AppSettingsModel> updateSettings(AppSettingsModel settings) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    _settings = settings;
    return _settings;
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => MockSettingsRepository());
```

- [ ] **Step 9: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
git add frontend/lib/repositories/dashboard/ frontend/lib/repositories/orders/ frontend/lib/services/orders/ frontend/lib/repositories/wallet/ frontend/lib/repositories/support/ frontend/lib/repositories/profile/ frontend/lib/repositories/notifications/ frontend/lib/repositories/settings/
git commit -m "Add operational domain mock repositories and order stream service"
```

---

### Task 17: Providers — onboarding domains

**Files:**
- Create: `frontend/lib/providers/authentication/auth_provider.dart`
- Create: `frontend/lib/providers/partner_registration/registration_form_provider.dart`
- Create: `frontend/lib/providers/document_verification/documents_provider.dart`
- Create: `frontend/lib/providers/bank_details/bank_details_provider.dart`
- Create: `frontend/lib/providers/verification_status/verification_status_provider.dart`
- Create: `frontend/lib/providers/training/training_provider.dart`
- Create: `frontend/lib/providers/agreement/agreement_provider.dart`
- Create: `frontend/lib/providers/approval/approval_provider.dart`

**Interfaces:**
- Consumes: repository providers from Task 15, models from Task 13.
- Produces: `authSessionProvider`, `otpUiProvider`, `registrationFormProvider`, `documentsProvider`, `bankDetailsProvider`, `verificationStepsProvider`, `trainingModulesProvider`, `agreementProvider`, `approvalStatusProvider` — consumed later by the corresponding feature screens (post-plan).

- [ ] **Step 1: Create `auth_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/authentication/auth_repository.dart';
import '../../models/authentication/auth_session_model.dart';

/// UI state: the phone number currently being entered/verified.
final phoneNumberUiProvider = StateProvider<String>((ref) => '');

/// Domain state: the authenticated session.
class AuthSessionNotifier extends AsyncNotifier<AuthSessionModel> {
  @override
  Future<AuthSessionModel> build() async => AuthSessionModel.empty;

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).verifyOtp(phoneNumber, otp),
    );
  }
}

final authSessionProvider = AsyncNotifierProvider<AuthSessionNotifier, AuthSessionModel>(
  AuthSessionNotifier.new,
);
```

- [ ] **Step 2: Create `registration_form_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/partner_registration/vehicle_model.dart';

/// UI state: in-progress selections across the multi-step registration flow.
class RegistrationFormState {
  final String fullName;
  final VehicleType? vehicleType;
  final String? state;
  final String? city;

  const RegistrationFormState({
    this.fullName = '',
    this.vehicleType,
    this.state,
    this.city,
  });

  RegistrationFormState copyWith({
    String? fullName,
    VehicleType? vehicleType,
    String? state,
    String? city,
  }) =>
      RegistrationFormState(
        fullName: fullName ?? this.fullName,
        vehicleType: vehicleType ?? this.vehicleType,
        state: state ?? this.state,
        city: city ?? this.city,
      );
}

class RegistrationFormNotifier extends Notifier<RegistrationFormState> {
  @override
  RegistrationFormState build() => const RegistrationFormState();

  void setFullName(String value) => state = state.copyWith(fullName: value);
  void setVehicleType(VehicleType value) => state = state.copyWith(vehicleType: value);
  void setZone(String state_, String city) => state = state.copyWith(state: state_, city: city);
}

final registrationFormProvider =
    NotifierProvider<RegistrationFormNotifier, RegistrationFormState>(
  RegistrationFormNotifier.new,
);
```

- [ ] **Step 3: Create `documents_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/document_verification/document_repository.dart';
import '../../models/document_verification/document_model.dart';

class DocumentsNotifier extends AsyncNotifier<List<DocumentModel>> {
  @override
  Future<List<DocumentModel>> build() => ref.watch(documentRepositoryProvider).getDocuments();

  Future<void> upload(DocumentType type, String filePath) async {
    final updated = await ref.read(documentRepositoryProvider).uploadDocument(type, filePath);
    state = AsyncData([
      for (final doc in state.value ?? [])
        if (doc.type == type) updated else doc,
    ]);
  }
}

final documentsProvider = AsyncNotifierProvider<DocumentsNotifier, List<DocumentModel>>(
  DocumentsNotifier.new,
);
```

- [ ] **Step 4: Create `bank_details_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/bank_details/bank_details_repository.dart';
import '../../models/bank_details/bank_details_model.dart';

class BankDetailsNotifier extends AsyncNotifier<BankDetailsModel?> {
  @override
  Future<BankDetailsModel?> build() => ref.watch(bankDetailsRepositoryProvider).getBankDetails();

  Future<void> save(BankDetailsModel details) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(bankDetailsRepositoryProvider).saveBankDetails(details);
      return details;
    });
  }
}

final bankDetailsProvider = AsyncNotifierProvider<BankDetailsNotifier, BankDetailsModel?>(
  BankDetailsNotifier.new,
);
```

- [ ] **Step 5: Create `verification_status_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/verification_status/verification_status_repository.dart';
import '../../models/verification_status/verification_step_model.dart';

final verificationStepsProvider = FutureProvider<List<VerificationStepModel>>(
  (ref) => ref.watch(verificationStatusRepositoryProvider).getSteps(),
);
```

- [ ] **Step 6: Create `training_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/training/training_repository.dart';
import '../../models/training/training_module_model.dart';

class TrainingModulesNotifier extends AsyncNotifier<List<TrainingModuleModel>> {
  @override
  Future<List<TrainingModuleModel>> build() => ref.watch(trainingRepositoryProvider).getModules();

  Future<void> markCompleted(String moduleId) async {
    await ref.read(trainingRepositoryProvider).markCompleted(moduleId);
    state = AsyncData([
      for (final module in state.value ?? [])
        if (module.id == moduleId) module.copyWith(isCompleted: true) else module,
    ]);
  }
}

final trainingModulesProvider = AsyncNotifierProvider<TrainingModulesNotifier, List<TrainingModuleModel>>(
  TrainingModulesNotifier.new,
);
```

- [ ] **Step 7: Create `agreement_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/agreement/agreement_repository.dart';
import '../../models/agreement/agreement_model.dart';

class AgreementNotifier extends Notifier<AgreementModel> {
  @override
  AgreementModel build() => const AgreementModel(
        termsAccepted: false,
        privacyAccepted: false,
        partnerAgreementAccepted: false,
      );

  void toggleTerms(bool value) => state = AgreementModel(
        termsAccepted: value,
        privacyAccepted: state.privacyAccepted,
        partnerAgreementAccepted: state.partnerAgreementAccepted,
      );

  void togglePrivacy(bool value) => state = AgreementModel(
        termsAccepted: state.termsAccepted,
        privacyAccepted: value,
        partnerAgreementAccepted: state.partnerAgreementAccepted,
      );

  void togglePartnerAgreement(bool value) => state = AgreementModel(
        termsAccepted: state.termsAccepted,
        privacyAccepted: state.privacyAccepted,
        partnerAgreementAccepted: value,
      );

  Future<void> submit() async {
    if (!state.allAccepted) return;
    await ref.read(agreementRepositoryProvider).acceptAgreement(state);
  }
}

final agreementProvider = NotifierProvider<AgreementNotifier, AgreementModel>(AgreementNotifier.new);
```

- [ ] **Step 8: Create `approval_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/approval/approval_repository.dart';
import '../../models/approval/approval_status_model.dart';

final approvalStatusProvider = FutureProvider<ApprovalStatusModel>(
  (ref) => ref.watch(approvalRepositoryProvider).getApprovalStatus(),
);
```

- [ ] **Step 9: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
git add frontend/lib/providers/authentication/ frontend/lib/providers/partner_registration/ frontend/lib/providers/document_verification/ frontend/lib/providers/bank_details/ frontend/lib/providers/verification_status/ frontend/lib/providers/training/ frontend/lib/providers/agreement/ frontend/lib/providers/approval/
git commit -m "Add onboarding domain Riverpod providers"
```

---

### Task 18: Providers — operational domains

**Files:**
- Create: `frontend/lib/providers/dashboard/dashboard_provider.dart`
- Create: `frontend/lib/providers/orders/active_order_provider.dart`
- Create: `frontend/lib/providers/orders/order_filter_ui_provider.dart`
- Create: `frontend/lib/providers/wallet/wallet_provider.dart`
- Create: `frontend/lib/providers/support/support_provider.dart`
- Create: `frontend/lib/providers/profile/profile_provider.dart`
- Create: `frontend/lib/providers/notifications/notifications_provider.dart`
- Create: `frontend/lib/providers/settings/settings_provider.dart`

**Interfaces:**
- Consumes: repository/service providers from Task 16, models from Task 14.
- Produces: `dashboardStatsProvider`, `activeOrderProvider`, `orderFilterUiProvider`, `walletProvider`, `transactionsProvider`, `supportTicketsProvider`, `profileProvider`, `ratingProvider`, `notificationsProvider`, `settingsProvider`.

- [ ] **Step 1: Create `dashboard_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/dashboard/dashboard_repository.dart';
import '../../models/dashboard/dashboard_stats_model.dart';

class DashboardStatsNotifier extends AsyncNotifier<DashboardStatsModel> {
  @override
  Future<DashboardStatsModel> build() => ref.watch(dashboardRepositoryProvider).getStats();

  Future<void> toggleOnline(bool isOnline) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).setOnline(isOnline),
    );
  }
}

final dashboardStatsProvider = AsyncNotifierProvider<DashboardStatsNotifier, DashboardStatsModel>(
  DashboardStatsNotifier.new,
);
```

- [ ] **Step 2: Create `active_order_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/orders/orders_repository.dart';
import '../../models/orders/order_model.dart';

class ActiveOrderNotifier extends AsyncNotifier<OrderModel?> {
  @override
  Future<OrderModel?> build() => ref.watch(ordersRepositoryProvider).getActiveOrder();

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ordersRepositoryProvider).updateOrderStatus(orderId, status),
    );
  }
}

final activeOrderProvider = AsyncNotifierProvider<ActiveOrderNotifier, OrderModel?>(
  ActiveOrderNotifier.new,
);
```

- [ ] **Step 3: Create `order_filter_ui_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OrderFilterType { all, ongoing, completed }

final orderFilterUiProvider = StateProvider<OrderFilterType>((ref) => OrderFilterType.all);
```

- [ ] **Step 4: Create `wallet_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/wallet/wallet_repository.dart';
import '../../models/wallet/wallet_model.dart';
import '../../models/wallet/transaction_model.dart';

final walletProvider = FutureProvider<WalletModel>(
  (ref) => ref.watch(walletRepositoryProvider).getWallet(),
);

final transactionsProvider = FutureProvider<List<TransactionModel>>(
  (ref) => ref.watch(walletRepositoryProvider).getTransactions(),
);
```

- [ ] **Step 5: Create `support_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/support/support_repository.dart';
import '../../models/support/support_ticket_model.dart';

class SupportTicketsNotifier extends AsyncNotifier<List<SupportTicketModel>> {
  @override
  Future<List<SupportTicketModel>> build() => ref.watch(supportRepositoryProvider).getTickets();

  Future<void> createTicket(String subject) async {
    final ticket = await ref.read(supportRepositoryProvider).createTicket(subject);
    state = AsyncData([...(state.value ?? []), ticket]);
  }
}

final supportTicketsProvider = AsyncNotifierProvider<SupportTicketsNotifier, List<SupportTicketModel>>(
  SupportTicketsNotifier.new,
);
```

- [ ] **Step 6: Create `profile_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../models/profile/partner_profile_model.dart';
import '../../models/profile/rating_model.dart';

final profileProvider = FutureProvider<PartnerProfileModel>(
  (ref) => ref.watch(profileRepositoryProvider).getProfile(),
);

final ratingProvider = FutureProvider<RatingModel>(
  (ref) => ref.watch(profileRepositoryProvider).getRating(),
);
```

- [ ] **Step 7: Create `notifications_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/notifications/notifications_repository.dart';
import '../../models/notifications/notification_model.dart';

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() =>
      ref.watch(notificationsRepositoryProvider).getNotifications();

  Future<void> markAsRead(String id) async {
    await ref.read(notificationsRepositoryProvider).markAsRead(id);
    state = AsyncData([
      for (final n in state.value ?? [])
        if (n.id == id) n.copyWith(isRead: true) else n,
    ]);
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);
```

- [ ] **Step 8: Create `settings_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/settings/settings_repository.dart';
import '../../models/settings/app_settings_model.dart';

class SettingsNotifier extends AsyncNotifier<AppSettingsModel> {
  @override
  Future<AppSettingsModel> build() => ref.watch(settingsRepositoryProvider).getSettings();

  Future<void> update(AppSettingsModel settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(settingsRepositoryProvider).updateSettings(settings),
    );
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettingsModel>(
  SettingsNotifier.new,
);
```

- [ ] **Step 9: Verify**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
git add frontend/lib/providers/dashboard/ frontend/lib/providers/orders/ frontend/lib/providers/wallet/ frontend/lib/providers/support/ frontend/lib/providers/profile/ frontend/lib/providers/notifications/ frontend/lib/providers/settings/
git commit -m "Add operational domain Riverpod providers"
```

---

### Task 19: Core routing

**Files:**
- Create: `frontend/lib/core/routes/app_routes.dart`
- Create: `frontend/lib/core/routes/placeholder_screen.dart`
- Create: `frontend/lib/core/routes/app_pages.dart`

**Interfaces:**
- Consumes: theme tokens (Task 2). `SplashScreen` from Task 20 (create Task 19's files first, then Task 20's `SplashScreen`, then wire it into `app_pages.dart` as the final step of Task 20 — see Task 20 Step 3).
- Produces: `AppRoutes` (one constant per feature screen), `PlaceholderScreen` (temporary stand-in for screens not yet built), `AppPages.pages` (the `GetPage` table) — consumed by `app.dart` in Task 20.

- [ ] **Step 1: Create `app_routes.dart`**

```dart
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const welcome = '/welcome';
  static const otp = '/otp';
  static const personalInfo = '/registration/personal-info';
  static const vehicleSelection = '/registration/vehicle-selection';
  static const deliveryZone = '/registration/delivery-zone';
  static const documentUpload = '/documents';
  static const bankDetails = '/bank-details';
  static const verificationStatus = '/verification-status';
  static const training = '/training';
  static const agreement = '/agreement';
  static const approval = '/approval';
  static const dashboard = '/dashboard';
  static const orders = '/orders';
  static const wallet = '/wallet';
  static const support = '/support';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const settings = '/settings';
}
```

- [ ] **Step 2: Create `placeholder_screen.dart`**

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Temporary stand-in for a route whose real screen hasn't been built yet
/// (screens are added one at a time in later sessions per the UI roadmap).
/// Delete each usage in app_pages.dart as its real screen replaces it.
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('$title — coming soon', style: AppTypography.body),
      ),
    );
  }
}
```

- [ ] **Step 3: Create `app_pages.dart`**

```dart
import 'package:get/get.dart';
import 'app_routes.dart';
import 'placeholder_screen.dart';
import '../../features/splash/screens/splash_screen.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.welcome, page: () => const PlaceholderScreen(title: 'Welcome')),
    GetPage(name: AppRoutes.otp, page: () => const PlaceholderScreen(title: 'OTP Verification')),
    GetPage(name: AppRoutes.personalInfo, page: () => const PlaceholderScreen(title: 'Personal Information')),
    GetPage(name: AppRoutes.vehicleSelection, page: () => const PlaceholderScreen(title: 'Vehicle Selection')),
    GetPage(name: AppRoutes.deliveryZone, page: () => const PlaceholderScreen(title: 'Delivery Zone')),
    GetPage(name: AppRoutes.documentUpload, page: () => const PlaceholderScreen(title: 'Document Upload')),
    GetPage(name: AppRoutes.bankDetails, page: () => const PlaceholderScreen(title: 'Bank Details')),
    GetPage(name: AppRoutes.verificationStatus, page: () => const PlaceholderScreen(title: 'Verification Status')),
    GetPage(name: AppRoutes.training, page: () => const PlaceholderScreen(title: 'Training')),
    GetPage(name: AppRoutes.agreement, page: () => const PlaceholderScreen(title: 'Agreement')),
    GetPage(name: AppRoutes.approval, page: () => const PlaceholderScreen(title: 'Approval')),
    GetPage(name: AppRoutes.dashboard, page: () => const PlaceholderScreen(title: 'Dashboard')),
    GetPage(name: AppRoutes.orders, page: () => const PlaceholderScreen(title: 'Orders')),
    GetPage(name: AppRoutes.wallet, page: () => const PlaceholderScreen(title: 'Wallet')),
    GetPage(name: AppRoutes.support, page: () => const PlaceholderScreen(title: 'Support')),
    GetPage(name: AppRoutes.profile, page: () => const PlaceholderScreen(title: 'Profile')),
    GetPage(name: AppRoutes.notifications, page: () => const PlaceholderScreen(title: 'Notifications')),
    GetPage(name: AppRoutes.settings, page: () => const PlaceholderScreen(title: 'Settings')),
  ];
}
```

Note: this file imports `SplashScreen`, which Task 20 creates. Do Task 20's Step 1 (create `SplashScreen`) before this task's verification step.

- [ ] **Step 4: Verify**

This depends on Task 20's `SplashScreen` existing — skip verification here and run it as part of Task 20 Step 5 instead.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/core/routes/
git commit -m "Add route names, placeholder screen, and GetX page table"
```

---

### Task 20: Feature folder scaffolding, Splash screen, and app wiring

**Files:**
- Create: `frontend/lib/features/splash/screens/splash_screen.dart`
- Create: `frontend/lib/features/<name>/screens/` and `frontend/lib/features/<name>/widgets/` (empty, `.gitkeep`) for the remaining 16 features: `onboarding_welcome`, `authentication`, `partner_registration`, `document_verification`, `bank_details`, `verification_status`, `training`, `agreement`, `approval`, `dashboard`, `orders`, `wallet`, `support`, `profile`, `notifications`, `settings`
- Create: `frontend/lib/app.dart`
- Modify: `frontend/lib/main.dart`

**Interfaces:**
- Consumes: `AppTheme.light` (Task 2), `AppRoutes`/`AppPages` (Task 19), `authSessionProvider` (Task 17).
- Produces: a runnable app — `main()` → `DeliveryPartnerApp` → `SplashScreen` → (after a delay) navigates to `AppRoutes.welcome`, which resolves to `PlaceholderScreen`.

- [ ] **Step 1: Create `splash_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Get.offAllNamed(AppRoutes.welcome);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Text(
          AppConstants.appName,
          style: AppTypography.h1.copyWith(color: Colors.white, fontSize: 28),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Scaffold remaining feature folders**

```bash
for feature in onboarding_welcome authentication partner_registration document_verification bank_details verification_status training agreement approval dashboard orders wallet support profile notifications settings; do
  mkdir -p "frontend/lib/features/$feature/screens" "frontend/lib/features/$feature/widgets"
  touch "frontend/lib/features/$feature/screens/.gitkeep" "frontend/lib/features/$feature/widgets/.gitkeep"
done
```

- [ ] **Step 3: Create `app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

class DeliveryPartnerApp extends StatelessWidget {
  const DeliveryPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Qikzoo Partner',
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 4: Replace `main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: DeliveryPartnerApp()));
}
```

- [ ] **Step 5: Verify — analyze**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Verify — app launches**

Run: `cd frontend && flutter run -d <device-id>` (use `flutter devices` to list available emulators/simulators/physical devices first)
Expected: app launches showing "Qikzoo Partner" on an indigo splash background, then after ~2 seconds auto-navigates to a screen reading "Welcome — coming soon".

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/ frontend/lib/app.dart frontend/lib/main.dart
git commit -m "Wire app entry point, splash screen, and scaffold remaining feature folders"
```

---

### Task 21: Final whole-project verification

**Files:** none created — verification only.

- [ ] **Step 1: Full static analysis**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Confirm dependency resolution is still clean**

Run: `cd frontend && flutter pub get`
Expected: `Got dependencies!`

- [ ] **Step 3: Confirm every domain folder exists on both sides of the type-first split**

Run:
```bash
for d in authentication partner_registration document_verification bank_details verification_status training agreement approval dashboard orders wallet support profile notifications settings; do
  test -d "frontend/lib/models/$d" && test -d "frontend/lib/providers/$d" && test -d "frontend/lib/repositories/$d" && echo "$d: OK" || echo "$d: MISSING"
done
```
Expected: every line ends in `OK`.

- [ ] **Step 4: Confirm all 17 feature folders exist**

Run:
```bash
for f in splash onboarding_welcome authentication partner_registration document_verification bank_details verification_status training agreement approval dashboard orders wallet support profile notifications settings; do
  test -d "frontend/lib/features/$f/screens" && test -d "frontend/lib/features/$f/widgets" && echo "$f: OK" || echo "$f: MISSING"
done
```
Expected: every line ends in `OK`.

- [ ] **Step 5: Manual run-through**

Run: `cd frontend && flutter run -d <device-id>` and confirm the splash-to-welcome-placeholder transition happens once more, end to end.

- [ ] **Step 6: Final commit (only if any of the above steps required fixes)**

```bash
git add frontend/
git commit -m "Fix issues found during final verification pass"
```

If no fixes were needed, skip this step — nothing to commit.
