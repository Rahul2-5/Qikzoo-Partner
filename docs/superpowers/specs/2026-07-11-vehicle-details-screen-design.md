# Vehicle Details Screen

## Purpose

Insert a new step into the partner registration flow that captures the
partner's vehicle number and vehicle model, immediately after they pick their
Partner Type (Bike / Cycle / E-Bike).

## Flow change

Current: Personal Info (step 0) → Partner Type (step 1) → Select City (step 2) → Documents

New: Personal Info (step 0) → Partner Type (step 1) → **Vehicle Details (step 2)** → Select City (step 3) → Documents

`StepProgressIndicator totalSteps` changes 4 → 5 on all four registration
screens (`personal_info_screen.dart`, `vehicle_selection_screen.dart`,
`select_city_screen.dart`, and the new `vehicle_details_screen.dart`).
`currentStep` shifts accordingly: Personal Info=0, Partner Type=1, Vehicle
Details=2, Select City=3.

`vehicle_selection_screen.dart`'s `_onContinue` navigates to the new
`AppRoutes.vehicleDetails` route instead of `AppRoutes.deliveryZone`. It no
longer calls `saveVehicle` — that call moves to the new screen's continue
button, since vehicle number and model are only known by then.

## New route

`AppRoutes.vehicleDetails = '/registration/vehicle-details'`, registered in
`app_pages.dart` pointing at the new screen.

## New files

- `lib/features/partner_registration/screens/vehicle_details_screen.dart`
- `lib/features/partner_registration/widgets/vehicle_type_display_field.dart`
  — read-only field showing the chosen vehicle type's icon + label (reuses
  the icon/label mapping already in `vehicle_selection_screen.dart`, moved
  into a shared place both screens can call — see Data model below).

## Fields

Rendered inside a card matching the Personal Info screen's layout
(`AppColors.surface` container, `AppRadius.card`, `AppColors.border`), each
wrapped in `LabeledField`:

1. **Vehicle Number** (`AppTextField`) — hidden entirely when
   `vehicleType == VehicleType.bicycle` (bicycles have no plates). Validated
   against `^[A-Za-z]{2}\s?\d{1,2}\s?[A-Za-z]{1,2}\s?\d{4}$`, input is
   uppercased as the user types, placeholder "MH 01 AB 1234", prefix icon
   `LucideIcons.creditCard` (or similar).
2. **Vehicle Type** (`VehicleTypeDisplayField`) — read-only, pre-filled from
   `registrationFormProvider.vehicleType`. Not editable on this screen; user
   must go back to Partner Type to change it.
3. **Vehicle Model** (`AppTextField`) — free text, required, placeholder
   "e.g. Honda Shine".

## Data model changes

- `VehicleModel` (`models/partner_registration/vehicle_model.dart`): add a
  `model` field (String?) alongside the existing `type` and
  `registrationNumber`.
- `RegistrationFormState` / `RegistrationFormNotifier`
  (`providers/partner_registration/registration_form_provider.dart`): add
  `vehicleNumber` and `vehicleModel` string fields with `setVehicleNumber`/
  `setVehicleModel` setters, plus a validity getter
  `isVehicleDetailsValid` that requires `vehicleModel` non-empty and (when
  `vehicleType != VehicleType.bicycle`) `vehicleNumber` to match the plate
  regex.

## Save behavior

The new screen's Continue button is enabled only when
`isVehicleDetailsValid` is true. On press it calls
`partnerRegistrationRepositoryProvider.saveVehicle` with the full
`VehicleModel` (type + registrationNumber + model), then navigates to
`AppRoutes.deliveryZone`.

## Icon/label mapping reuse

`vehicle_selection_screen.dart` currently has private `_label`/`_image`
methods mapping `VehicleType` → display label/asset. These move to a small
shared helper (e.g. static methods on a `VehicleTypeDisplay` class in
`models/partner_registration/vehicle_model.dart` or a new file in
`core/constants/`) so both the Partner Type cards and the new read-only
display field use the same source of truth.

## Out of scope

- Editing vehicle type from this screen.
- Any backend/API integration beyond the existing mock repository.
