# Vehicle Details Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Vehicle Details" step (vehicle number + read-only vehicle type + vehicle model) into the partner registration flow, between Partner Type and Select City.

**Architecture:** Standard Flutter/Riverpod/GetX feature-screen pattern already used by this codebase's `partner_registration` feature: a `ConsumerStatefulWidget` screen reads/writes a shared `registrationFormProvider`, calls a repository method on Continue, and navigates via `Get.toNamed`. A pure-Dart validity/regex helper is unit-testable in isolation from widgets.

**Tech Stack:** Flutter, flutter_riverpod, get (GetX routing), equatable, lucide_icons, flutter_test.

## Global Constraints

- `totalSteps` on every `StepProgressIndicator` in the registration flow must read `5` (was `4`).
- Vehicle Number regex: `^[A-Za-z]{2}\s?\d{1,2}\s?[A-Za-z]{1,2}\s?\d{4}$`.
- Vehicle Number field is hidden and not required when `vehicleType == VehicleType.bicycle`.
- Follow existing widget conventions: `LabeledField` wraps every input, `AppTextField` for text inputs, `AppColors`/`AppSpacing`/`AppRadius`/`AppTypography` for styling — no new design tokens.

---

### Task 1: Vehicle type display helper + model/state fields

**Files:**
- Modify: `frontend/lib/models/partner_registration/vehicle_model.dart`
- Modify: `frontend/lib/providers/partner_registration/registration_form_provider.dart`
- Test: `frontend/test/models/partner_registration/vehicle_model_test.dart`
- Test: `frontend/test/providers/partner_registration/registration_form_provider_test.dart`

**Interfaces:**
- Produces: `VehicleType.label` (String getter), `VehicleType.imageAsset` (String getter) — extension getters on the existing `VehicleType` enum.
- Produces: `VehicleModel(type, registrationNumber, model)` — `model` is a new optional `String?` field.
- Produces: `RegistrationFormState.vehicleNumber` (String, default `''`), `RegistrationFormState.vehicleModel` (String, default `''`), `RegistrationFormState.isVehicleDetailsValid` (bool getter).
- Produces: `RegistrationFormNotifier.setVehicleNumber(String)`, `RegistrationFormNotifier.setVehicleModel(String)`.

- [ ] **Step 1: Write failing tests for the `VehicleType` display extension**

Create `frontend/test/models/partner_registration/vehicle_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/partner_registration/vehicle_model.dart';

void main() {
  group('VehicleType display', () {
    test('scooter and bike map to Bike Partner / bike_3d.png', () {
      expect(VehicleType.scooter.label, 'Bike Partner');
      expect(VehicleType.scooter.imageAsset, 'assets/images/bike_3d.png');
      expect(VehicleType.bike.label, 'Bike Partner');
      expect(VehicleType.bike.imageAsset, 'assets/images/bike_3d.png');
    });

    test('bicycle maps to Cycle Partner / cycle_3d.png', () {
      expect(VehicleType.bicycle.label, 'Cycle Partner');
      expect(VehicleType.bicycle.imageAsset, 'assets/images/cycle_3d.png');
    });

    test('electricVehicle maps to E-Bike Partner / e-bike_3d.png', () {
      expect(VehicleType.electricVehicle.label, 'E-Bike Partner');
      expect(VehicleType.electricVehicle.imageAsset,
          'assets/images/e-bike_3d.png');
    });
  });

  group('VehicleModel', () {
    test('carries an optional model field', () {
      const vehicle = VehicleModel(
        type: VehicleType.scooter,
        registrationNumber: 'MH01AB1234',
        model: 'Honda Shine',
      );
      expect(vehicle.model, 'Honda Shine');
      expect(
        vehicle,
        const VehicleModel(
          type: VehicleType.scooter,
          registrationNumber: 'MH01AB1234',
          model: 'Honda Shine',
        ),
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run (from `frontend/`): `flutter test test/models/partner_registration/vehicle_model_test.dart`
Expected: FAIL — `label`/`imageAsset` undefined, `model` param undefined.

- [ ] **Step 3: Implement `VehicleType` extension and extend `VehicleModel`**

Replace the full contents of `frontend/lib/models/partner_registration/vehicle_model.dart`:

```dart
import 'package:equatable/equatable.dart';

enum VehicleType { bike, scooter, bicycle, electricVehicle }

extension VehicleTypeDisplay on VehicleType {
  String get label => switch (this) {
        VehicleType.scooter => 'Bike Partner',
        VehicleType.bicycle => 'Cycle Partner',
        VehicleType.electricVehicle => 'E-Bike Partner',
        VehicleType.bike => 'Bike Partner',
      };

  String get imageAsset => switch (this) {
        VehicleType.scooter => 'assets/images/bike_3d.png',
        VehicleType.bicycle => 'assets/images/cycle_3d.png',
        VehicleType.electricVehicle => 'assets/images/e-bike_3d.png',
        VehicleType.bike => 'assets/images/bike_3d.png',
      };
}

class VehicleModel extends Equatable {
  final VehicleType type;
  final String? registrationNumber;
  final String? model;

  const VehicleModel({
    required this.type,
    this.registrationNumber,
    this.model,
  });

  @override
  List<Object?> get props => [type, registrationNumber, model];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/partner_registration/vehicle_model_test.dart`
Expected: PASS (all 4 tests).

- [ ] **Step 5: Write failing tests for `RegistrationFormState`/`Notifier` additions**

Create `frontend/test/providers/partner_registration/registration_form_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/partner_registration/vehicle_model.dart';
import 'package:delivery_partner_app/providers/partner_registration/registration_form_provider.dart';

void main() {
  group('vehicle details validity', () {
    test('invalid with empty model, regardless of type', () {
      const state = RegistrationFormState(
        vehicleType: VehicleType.scooter,
        vehicleNumber: 'MH01AB1234',
        vehicleModel: '',
      );
      expect(state.isVehicleDetailsValid, isFalse);
    });

    test('bicycle only needs a model, number is ignored', () {
      const state = RegistrationFormState(
        vehicleType: VehicleType.bicycle,
        vehicleNumber: '',
        vehicleModel: 'Hero Sprint',
      );
      expect(state.isVehicleDetailsValid, isTrue);
    });

    test('scooter needs a model and a well-formed number', () {
      const invalid = RegistrationFormState(
        vehicleType: VehicleType.scooter,
        vehicleNumber: 'not-a-plate',
        vehicleModel: 'Honda Shine',
      );
      expect(invalid.isVehicleDetailsValid, isFalse);

      const valid = RegistrationFormState(
        vehicleType: VehicleType.scooter,
        vehicleNumber: 'MH 01 AB 1234',
        vehicleModel: 'Honda Shine',
      );
      expect(valid.isVehicleDetailsValid, isTrue);
    });

    test('electricVehicle needs a model and a well-formed number', () {
      const state = RegistrationFormState(
        vehicleType: VehicleType.electricVehicle,
        vehicleNumber: 'KA05MZ9021',
        vehicleModel: 'Ather 450X',
      );
      expect(state.isVehicleDetailsValid, isTrue);
    });

    test('invalid when vehicleType is null', () {
      const state = RegistrationFormState(
        vehicleNumber: 'MH01AB1234',
        vehicleModel: 'Honda Shine',
      );
      expect(state.isVehicleDetailsValid, isFalse);
    });
  });

  group('RegistrationFormNotifier vehicle detail setters', () {
    test('setVehicleNumber and setVehicleModel update state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(registrationFormProvider.notifier);

      notifier.setVehicleNumber('MH01AB1234');
      notifier.setVehicleModel('Honda Shine');

      final state = container.read(registrationFormProvider);
      expect(state.vehicleNumber, 'MH01AB1234');
      expect(state.vehicleModel, 'Honda Shine');
    });
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/providers/partner_registration/registration_form_provider_test.dart`
Expected: FAIL — `vehicleNumber`, `vehicleModel`, `isVehicleDetailsValid` undefined.

- [ ] **Step 7: Implement the state/notifier additions**

Replace the full contents of
`frontend/lib/providers/partner_registration/registration_form_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/partner_registration/personal_info_model.dart';
import '../../models/partner_registration/vehicle_model.dart';

/// UI state: in-progress selections across the multi-step registration flow.
class RegistrationFormState {
  final String fullName;
  final String email;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String emergencyContactName;
  final String emergencyContactNumber;
  final Relation? relation;
  final String relationOther;
  final String referralCode;
  final VehicleType? vehicleType;
  final String vehicleNumber;
  final String vehicleModel;
  final String? state;
  final String? city;

  static final RegExp _plateRegExp =
      RegExp(r'^[A-Za-z]{2}\s?\d{1,2}\s?[A-Za-z]{1,2}\s?\d{4}$');

  const RegistrationFormState({
    this.fullName = '',
    this.email = '',
    this.dateOfBirth,
    this.gender,
    this.emergencyContactName = '',
    this.emergencyContactNumber = '',
    this.relation,
    this.relationOther = '',
    this.referralCode = '',
    this.vehicleType,
    this.vehicleNumber = '',
    this.vehicleModel = '',
    this.state,
    this.city,
  });

  bool get isPersonalInfoValid =>
      fullName.trim().isNotEmpty &&
      dateOfBirth != null &&
      gender != null &&
      emergencyContactName.trim().isNotEmpty &&
      emergencyContactNumber.trim().length == 10 &&
      relation != null &&
      (relation != Relation.other || relationOther.trim().isNotEmpty);

  bool get isVehicleDetailsValid {
    if (vehicleType == null || vehicleModel.trim().isEmpty) return false;
    if (vehicleType == VehicleType.bicycle) return true;
    return _plateRegExp.hasMatch(vehicleNumber.trim());
  }

  RegistrationFormState copyWith({
    String? fullName,
    String? email,
    DateTime? dateOfBirth,
    Gender? gender,
    String? emergencyContactName,
    String? emergencyContactNumber,
    Relation? relation,
    String? relationOther,
    String? referralCode,
    VehicleType? vehicleType,
    String? vehicleNumber,
    String? vehicleModel,
    String? state,
    String? city,
  }) =>
      RegistrationFormState(
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        emergencyContactName: emergencyContactName ?? this.emergencyContactName,
        emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
        relation: relation ?? this.relation,
        relationOther: relationOther ?? this.relationOther,
        referralCode: referralCode ?? this.referralCode,
        vehicleType: vehicleType ?? this.vehicleType,
        vehicleNumber: vehicleNumber ?? this.vehicleNumber,
        vehicleModel: vehicleModel ?? this.vehicleModel,
        state: state ?? this.state,
        city: city ?? this.city,
      );
}

class RegistrationFormNotifier extends Notifier<RegistrationFormState> {
  @override
  RegistrationFormState build() => const RegistrationFormState();

  void setFullName(String value) => state = state.copyWith(fullName: value);
  void setEmail(String value) => state = state.copyWith(email: value);
  void setDateOfBirth(DateTime value) => state = state.copyWith(dateOfBirth: value);
  void setGender(Gender value) => state = state.copyWith(gender: value);
  void setEmergencyContactName(String value) => state = state.copyWith(emergencyContactName: value);
  void setEmergencyContactNumber(String value) => state = state.copyWith(emergencyContactNumber: value);
  void setRelation(Relation value) => state = state.copyWith(relation: value);
  void setRelationOther(String value) => state = state.copyWith(relationOther: value);
  void setReferralCode(String value) => state = state.copyWith(referralCode: value);
  void setVehicleType(VehicleType value) => state = state.copyWith(vehicleType: value);
  void setVehicleNumber(String value) => state = state.copyWith(vehicleNumber: value);
  void setVehicleModel(String value) => state = state.copyWith(vehicleModel: value);
  void setZone(String state_, String city) => state = state.copyWith(state: state_, city: city);
}

final registrationFormProvider =
    NotifierProvider<RegistrationFormNotifier, RegistrationFormState>(
  RegistrationFormNotifier.new,
);
```

- [ ] **Step 8: Run tests to verify they pass**

Run:
`flutter test test/providers/partner_registration/registration_form_provider_test.dart`
`flutter test test/models/partner_registration/vehicle_model_test.dart`
Expected: PASS.

- [ ] **Step 9: Update `vehicle_selection_screen.dart` to use the new extension instead of its private `_label`/`_image` methods**

In `frontend/lib/features/partner_registration/screens/vehicle_selection_screen.dart`,
delete the `_label` and `_image` private methods (lines with
`String _label(VehicleType type) => switch...` and
`String _image(VehicleType type) => switch...`), and update the two call
sites inside the `VehicleTypeCard(...)` constructor call:

```dart
                        VehicleTypeCard(
                          imageAsset: options[i].imageAsset,
                          label: options[i].label,
```

- [ ] **Step 10: Run full test suite and confirm no regressions**

Run: `flutter test`
Expected: All tests PASS (no analyzer errors from the removed methods —
grep the file for `_label(` / `_image(` to confirm no other call sites
remain).

- [ ] **Step 11: Commit**

```bash
git add frontend/lib/models/partner_registration/vehicle_model.dart \
  frontend/lib/providers/partner_registration/registration_form_provider.dart \
  frontend/lib/features/partner_registration/screens/vehicle_selection_screen.dart \
  frontend/test/models/partner_registration/vehicle_model_test.dart \
  frontend/test/providers/partner_registration/registration_form_provider_test.dart
git commit -m "Add vehicle type display extension and vehicle details form state"
```

---

### Task 2: Read-only `VehicleTypeDisplayField` widget

**Files:**
- Create: `frontend/lib/features/partner_registration/widgets/vehicle_type_display_field.dart`
- Test: `frontend/test/features/partner_registration/widgets/vehicle_type_display_field_test.dart`

**Interfaces:**
- Consumes: `VehicleType.label`, `VehicleType.imageAsset` (from Task 1).
- Produces: `VehicleTypeDisplayField({required VehicleType vehicleType})` — a `StatelessWidget`.

- [ ] **Step 1: Write the failing widget test**

Create `frontend/test/features/partner_registration/widgets/vehicle_type_display_field_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/vehicle_type_display_field.dart';
import 'package:delivery_partner_app/models/partner_registration/vehicle_model.dart';

void main() {
  testWidgets('shows the label for the given vehicle type', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VehicleTypeDisplayField(vehicleType: VehicleType.electricVehicle),
        ),
      ),
    );

    expect(find.text('E-Bike Partner'), findsOneWidget);
  });

  testWidgets('renders the vehicle type image asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VehicleTypeDisplayField(vehicleType: VehicleType.bicycle),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/cycle_3d.png',
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/partner_registration/widgets/vehicle_type_display_field_test.dart`
Expected: FAIL — file `vehicle_type_display_field.dart` doesn't exist.

- [ ] **Step 3: Implement the widget**

Create `frontend/lib/features/partner_registration/widgets/vehicle_type_display_field.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/partner_registration/vehicle_model.dart';

/// Read-only display of the vehicle type chosen on the Partner Type screen.
/// Not editable here — the user must go back to Partner Type to change it.
class VehicleTypeDisplayField extends StatelessWidget {
  final VehicleType vehicleType;

  const VehicleTypeDisplayField({super.key, required this.vehicleType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Image.asset(vehicleType.imageAsset, width: 24, height: 24),
          const SizedBox(width: 12),
          Text(vehicleType.label, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/partner_registration/widgets/vehicle_type_display_field_test.dart`
Expected: PASS (both tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/partner_registration/widgets/vehicle_type_display_field.dart \
  frontend/test/features/partner_registration/widgets/vehicle_type_display_field_test.dart
git commit -m "Add read-only vehicle type display field"
```

---

### Task 3: `vehicle_details_screen.dart` + route wiring + step count bump

**Files:**
- Create: `frontend/lib/features/partner_registration/screens/vehicle_details_screen.dart`
- Modify: `frontend/lib/core/routes/app_routes.dart:11` (add `vehicleDetails` route constant after `vehicleSelection`)
- Modify: `frontend/lib/core/routes/app_pages.dart` (import + register the new `GetPage`)
- Modify: `frontend/lib/features/partner_registration/screens/vehicle_selection_screen.dart` (navigate to the new route instead of saving+navigating to delivery zone; bump `totalSteps` to 5)
- Modify: `frontend/lib/features/partner_registration/screens/personal_info_screen.dart:99` (bump `totalSteps` to 5)
- Modify: `frontend/lib/features/partner_registration/screens/select_city_screen.dart:150` (bump `totalSteps` to 5, `currentStep` to 3)

**Interfaces:**
- Consumes: `VehicleTypeDisplayField` (Task 2), `RegistrationFormState.isVehicleDetailsValid`, `.setVehicleNumber`, `.setVehicleModel` (Task 1), `VehicleModel(type, registrationNumber, model)` (Task 1), `partnerRegistrationRepositoryProvider.saveVehicle(VehicleModel)` (existing).
- Produces: `AppRoutes.vehicleDetails` route string, `VehicleDetailsScreen` widget registered at that route.

- [ ] **Step 1: Add the route constant**

In `frontend/lib/core/routes/app_routes.dart`, after line 11
(`static const vehicleSelection = ...`), add:

```dart
  static const vehicleDetails = '/registration/vehicle-details';
```

- [ ] **Step 2: Bump step counts on the three existing registration screens**

In `frontend/lib/features/partner_registration/screens/personal_info_screen.dart`,
change:
```dart
                      const StepProgressIndicator(
                          totalSteps: 4, currentStep: 0),
```
to:
```dart
                      const StepProgressIndicator(
                          totalSteps: 5, currentStep: 0),
```

In `frontend/lib/features/partner_registration/screens/vehicle_selection_screen.dart`,
change:
```dart
                      const StepProgressIndicator(
                          totalSteps: 4, currentStep: 1),
```
to:
```dart
                      const StepProgressIndicator(
                          totalSteps: 5, currentStep: 1),
```

In `frontend/lib/features/partner_registration/screens/select_city_screen.dart`,
change:
```dart
                      const StepProgressIndicator(
                          totalSteps: 4, currentStep: 2),
```
to:
```dart
                      const StepProgressIndicator(
                          totalSteps: 5, currentStep: 3),
```

- [ ] **Step 3: Update `vehicle_selection_screen.dart`'s `_onContinue` to navigate to the new screen instead of saving and going to delivery zone**

In `frontend/lib/features/partner_registration/screens/vehicle_selection_screen.dart`,
replace the `_onContinue` method:

```dart
  Future<void> _onContinue(VehicleType selected) async {
    setState(() => _isSaving = true);
    await ref
        .read(partnerRegistrationRepositoryProvider)
        .saveVehicle(VehicleModel(type: selected));
    if (!mounted) return;
    setState(() => _isSaving = false);
    Get.toNamed(AppRoutes.deliveryZone);
  }
```

with:

```dart
  void _onContinue(VehicleType selected) {
    ref.read(registrationFormProvider.notifier).setVehicleType(selected);
    Get.toNamed(AppRoutes.vehicleDetails);
  }
```

This screen no longer saves via the repository or shows a loading spinner,
since it's a pure local selection now — the actual save happens on the new
Vehicle Details screen. Update the `onPressed` call site (still inside the
same file, in the `PrimaryCtaButton`):

```dart
              PrimaryCtaButton(
                label: 'Continue',
                trailingIcon: LucideIcons.arrowRight,
                onPressed:
                    selected != null ? () => _onContinue(selected) : null,
              ),
```

(drop `isLoading: _isSaving` from this widget). Also delete the now-unused
`_isSaving` field (`bool _isSaving = false;`) from the state class, and
remove the now-unused `partnerRegistrationRepositoryProvider` import if no
other reference to it remains in the file (check with grep before removing
the import line).

- [ ] **Step 4: Create the Vehicle Details screen**

Create `frontend/lib/features/partner_registration/screens/vehicle_details_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/partner_registration/vehicle_model.dart';
import '../../../providers/partner_registration/registration_form_provider.dart';
import '../../../repositories/partner_registration/partner_registration_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/step_progress_indicator.dart';
import '../widgets/labeled_field.dart';
import '../widgets/vehicle_type_display_field.dart';

class VehicleDetailsScreen extends ConsumerStatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  ConsumerState<VehicleDetailsScreen> createState() =>
      _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends ConsumerState<VehicleDetailsScreen> {
  final _vehicleNumberController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(registrationFormProvider);
    _vehicleNumberController.text = formState.vehicleNumber;
    _vehicleModelController.text = formState.vehicleModel;
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _vehicleModelController.dispose();
    super.dispose();
  }

  Future<void> _onContinue(RegistrationFormState formState) async {
    setState(() => _isSaving = true);
    await ref.read(partnerRegistrationRepositoryProvider).saveVehicle(
          VehicleModel(
            type: formState.vehicleType!,
            registrationNumber: formState.vehicleType == VehicleType.bicycle
                ? null
                : formState.vehicleNumber,
            model: formState.vehicleModel,
          ),
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    Get.toNamed(AppRoutes.deliveryZone);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(registrationFormProvider);
    final formNotifier = ref.read(registrationFormProvider.notifier);
    final vehicleType = formState.vehicleType;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              IconButtonCustom(
                  icon: LucideIcons.arrowLeft, onPressed: () => Get.back()),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepProgressIndicator(
                          totalSteps: 5, currentStep: 2),
                      const SizedBox(height: AppSpacing.lg),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.h1.copyWith(fontSize: 26),
                          children: [
                            const TextSpan(
                                text: 'Vehicle ',
                                style: TextStyle(color: AppColors.textPrimary)),
                            TextSpan(
                              text: 'Details',
                              style: TextStyle(
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                          colors: AppColors.ctaGradient)
                                      .createShader(
                                          const Rect.fromLTWH(0, 0, 120, 26)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Enter your vehicle information',
                        style: AppTypography.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (vehicleType != VehicleType.bicycle) ...[
                              LabeledField(
                                label: 'Vehicle Number',
                                child: AppTextField(
                                  label: 'Vehicle Number',
                                  controller: _vehicleNumberController,
                                  showFloatingLabel: false,
                                  hint: 'MH 01 AB 1234',
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  inputFormatters: [UpperCaseTextFormatter()],
                                  prefixIcon: const Icon(
                                    LucideIcons.creditCard,
                                    color: AppColors.secondary,
                                    size: 20,
                                  ),
                                  onChanged: formNotifier.setVehicleNumber,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            LabeledField(
                              label: 'Vehicle Type',
                              child: VehicleTypeDisplayField(
                                vehicleType: vehicleType!,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            LabeledField(
                              label: 'Vehicle Model',
                              child: AppTextField(
                                label: 'Vehicle Model',
                                controller: _vehicleModelController,
                                showFloatingLabel: false,
                                hint: 'e.g. Honda Shine',
                                prefixIcon: const Icon(
                                  LucideIcons.tag,
                                  color: AppColors.secondary,
                                  size: 20,
                                ),
                                onChanged: formNotifier.setVehicleModel,
                              ),
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
                label: 'Continue',
                trailingIcon: LucideIcons.arrowRight,
                isLoading: _isSaving,
                onPressed: formState.isVehicleDetailsValid
                    ? () => _onContinue(formState)
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
```

Note: `AppTextField` does not currently expose a `textCapitalization`
parameter (see `frontend/lib/shared/widgets/inputs/app_text_field.dart`).
Before using it above, add the parameter — in
`frontend/lib/shared/widgets/inputs/app_text_field.dart`, add a field
`final TextCapitalization textCapitalization;` with default
`this.textCapitalization = TextCapitalization.none,` in the constructor, and
pass `textCapitalization: textCapitalization,` into the `TextField(...)`
call.

- [ ] **Step 5: Register the route**

In `frontend/lib/core/routes/app_pages.dart`, add the import (alongside the
existing `vehicle_selection_screen.dart` import):

```dart
import '../../features/partner_registration/screens/vehicle_details_screen.dart';
```

And add the `GetPage` entry right after the `vehicleSelection` entry:

```dart
    GetPage(
        name: AppRoutes.vehicleDetails,
        page: () => const VehicleDetailsScreen()),
```

- [ ] **Step 6: Analyze and confirm no compile errors**

Run (from `frontend/`): `flutter analyze`
Expected: No errors referencing `vehicle_details_screen.dart`,
`vehicle_selection_screen.dart`, `app_pages.dart`, `app_routes.dart`, or
`app_text_field.dart`.

- [ ] **Step 7: Run the full test suite**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 8: Manual verification**

Run: `flutter run` (or use the project's existing `run` workflow), walk
through: Personal Info → Partner Type → pick "Bike Partner" → Vehicle
Details shows Vehicle Number + Vehicle Type ("Bike Partner", bike_3d icon) +
Vehicle Model, Continue disabled until both are filled with a valid plate
number → Continue saves and lands on Select City. Repeat picking "Cycle
Partner" and confirm the Vehicle Number field is absent and Continue only
requires Vehicle Model.

- [ ] **Step 9: Commit**

```bash
git add frontend/lib/core/routes/app_routes.dart \
  frontend/lib/core/routes/app_pages.dart \
  frontend/lib/features/partner_registration/screens/vehicle_details_screen.dart \
  frontend/lib/features/partner_registration/screens/vehicle_selection_screen.dart \
  frontend/lib/features/partner_registration/screens/personal_info_screen.dart \
  frontend/lib/features/partner_registration/screens/select_city_screen.dart \
  frontend/lib/shared/widgets/inputs/app_text_field.dart
git commit -m "Add Vehicle Details screen to registration flow"
```

---

## Self-Review Notes

- **Spec coverage:** flow reordering (Task 3 steps 1-3), new route (Task 3
  step 5), Vehicle Number regex + hide-for-bicycle (Task 1 step 7, Task 3
  step 4), read-only Vehicle Type field (Task 2), Vehicle Model field (Task
  3 step 4), save-on-new-screen behavior (Task 3 steps 3-4), shared
  label/asset helper (Task 1 steps 3, 9) — all covered.
- **Type consistency:** `VehicleModel(type, registrationNumber, model)` used
  identically in Task 1 (definition) and Task 3 Step 4 (`_onContinue`).
  `RegistrationFormState.isVehicleDetailsValid`,
  `.setVehicleNumber`/`.setVehicleModel` defined in Task 1, consumed as-is
  in Task 3. `VehicleTypeDisplayField(vehicleType: ...)` defined in Task 2,
  consumed identically in Task 3.
