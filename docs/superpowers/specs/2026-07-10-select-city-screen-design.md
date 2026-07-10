# Select City Screen (Delivery Zone step 1)

## Problem

`AppRoutes.deliveryZone` currently renders a generic `PlaceholderScreen`. We
need a real "Select your City" screen matching the provided mockup: search,
a "Current Location" option using real GPS, and a list of popular cities.

## Design

**Route:** `select_city_screen.dart` replaces the `PlaceholderScreen` at
`AppRoutes.deliveryZone` in `app_pages.dart`. Same screen shell as
`PersonalInfoScreen`: back arrow, `StepProgressIndicator(totalSteps: 4,
currentStep: 2)`, gradient title ("Select your **City**"), subtitle,
`ResponsiveFrame`, `PrimaryCtaButton` "Continue".

**City data** (`core/constants/city_data.dart`): static list of `{name,
state}` — Mumbai/Maharashtra, Delhi/Delhi, Bangalore/Karnataka,
Pune/Maharashtra, Hyderabad/Telangana. `state` is derived from the picked
city, never entered by the user.

**Search:** existing `SearchBarCustom` filters the list client-side
(case-insensitive substring on city name). No matches renders the existing
`EmptyState` widget.

**City list tile** (`widgets/city_list_tile.dart`, new): leading icon in a
tinted circle (single consistent Lucide icon — no per-city landmark assets
exist in this project), city name, trailing radio indicator. New minimal
radio-dot visual (no existing shared radio widget to reuse).

**Current Location** (`widgets/current_location_tile.dart`, new):
- New dependencies: `geolocator`, `geocoding`.
- Android: add `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` to
  `AndroidManifest.xml`. iOS: add `NSLocationWhenInUseUsageDescription` to
  `Info.plist`.
- Tap → shows a spinner in place of the leading icon → `Geolocator
  .getCurrentPosition()` (requesting permission via geolocator's own
  `checkPermission`/`requestPermission` APIs, no separate
  `permission_handler` dependency) → `geocoding.placemarkFromCoordinates()`
  to resolve locality/city name → case-insensitive match against the
  supported city list.
  - Match → selects that city below, scrolls it into view.
  - No match / unsupported city → inline dismissible banner: "We're not
    available in `<City>` yet — pick from the list below."
  - Permission denied → inline banner: "Location permission denied — please
    pick your city manually."

**State/submission:** reuses existing `RegistrationFormState.setZone(state,
city)`. Continue enabled once a city is selected. `_onContinue` calls
`setZone`, then `partnerRegistrationRepositoryProvider.saveDeliveryZone(
DeliveryZoneModel(state: ..., city: ..., preferredZone: ''))` (preferredZone
left for a future screen), then navigates to `AppRoutes.documentUpload`.

## Out of scope

- `preferredZone`/locality picker (future screen).
- Per-city landmark icon assets.
- Cities beyond the fixed 5-city list.
