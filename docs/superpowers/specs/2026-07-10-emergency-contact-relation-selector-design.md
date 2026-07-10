# Emergency Contact Relation Selector

## Problem

On the "Tell us about yourself" screen, the emergency contact's relation to the
partner was typed inline into the name field (hint: "e.g. Suresh Verma
(Father)"). This is error-prone and unstructured. We want a dedicated
relation selector with common options and a free-text fallback.

## Design

**Model** (`personal_info_model.dart`):
- Add `enum Relation { father, mother, brother, other }`.
- `PersonalInfoModel` gains `relation` (required `Relation`) and
  `relationOther` (`String?`, populated only when `relation == Relation.other`).

**Widget** (`relation_selector.dart`, new, in
`features/partner_registration/widgets/`):
- Mirrors `GenderSelector`: a `Row` of 4 `FilterChipCustom` chips (Father,
  Mother, Brother, Other).
- When `Relation.other` is selected, renders an `AppTextField` below the chip
  row for typing the custom relation.

**Screen** (`personal_info_screen.dart`):
- New `LabeledField(label: 'Relation to Emergency Contact', child:
  RelationSelector(...))` placed before the "Emergency Contact Name" field.
- "Emergency Contact Name" field simplified: label becomes `'Emergency
  Contact Name'` (was "... (with relation)"), hint becomes `'e.g. Suresh
  Verma'`.
- New controller for the custom relation text, wired to
  `formNotifier.setRelationOther`.

**State** (`registration_form_provider.dart`):
- Add `Relation? relation` and `String relationOther` to
  `RegistrationFormState`, with `setRelation` / `setRelationOther` on the
  notifier.
- `isPersonalInfoValid` additionally requires `relation != null && (relation
  != Relation.other || relationOther.trim().isNotEmpty)`.

**Submission** (`_onContinue`):
- Passes `relation: formState.relation!` and `relationOther:
  formState.relation == Relation.other ? formState.relationOther : null`.

## Out of scope

- Backend/API contract changes beyond passing the new fields through
  `PersonalInfoModel`.
- Additional relation types beyond Father/Mother/Brother/Other.
