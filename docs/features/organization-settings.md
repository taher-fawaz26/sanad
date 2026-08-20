# Organization Settings (Provider)

## Purpose

Lets a provider view and edit their business profile: identity/description,
service categories, social profiles, working hours, and legal documents; also
surfaces profile-completion status and a KPI/overview hub.

## Location

`apps/sanad_provider/lib/src/features/organization_settings/`

## User Flow

Provider opens the **General Settings** page → taps a section's edit control
(identity/description, categories, social profiles, working hours) → a bottom
sheet collects the change → on confirm the page dispatches a `*Saved` event →
the bloc `PATCH`es settings and merges the result into in-memory state → the
section re-renders. Legal documents open a separate document-flow sub-page.

## Architecture

Single-feature Clean Architecture. One root bloc (`OrganizationSettingsBloc`) is
the source of truth every section reads from; edits go through a shared
`_patchSettings` helper. Auxiliary blocs cover the header, provider completion,
and overview.

## Main Screens

- `presentation/pages/general_settings_page.dart` — the page + section list.
- `presentation/legal_documents/legal_documents_page.dart` — legal docs sub-flow
  (hosts a `DocumentFlowBloc`; see [registration.md](registration.md)).
- Edit bottom sheets in `presentation/widgets/bottom_sheets/`
  (`edit_identity_bottom_sheet.dart`, `edit_working_hours_bottom_sheet.dart`,
  `edit_category_bottom_sheet.dart`, `edit_social_profiles_bottom_sheet.dart`).

## Main State Management

- `presentation/bloc/organization_settings/organization_settings_bloc.dart` —
  loads settings/working-hours/completion/categories; handles
  `OrganizationSettingsDescriptionSaved`, `…CategoriesSaved`,
  `…SocialProfilesSaved`, `…WorkingHoursSaved`, `…MediaUpdated`. Submit events use
  the `droppable()` transformer. State carries `status`/`saveStatus` (`RequestStatus`),
  `organization`, `saveFailure`, and a `pendingDescription` draft.
- Also: `identity_header/`, `provider_completion/`, `provider_overview/` blocs.

## Domain Models

`OrganizationProfileEntity`, `WorkingHoursDayEntity` / `WorkingHoursSlotEntity`,
`CategoryEntity`, `SocialProfilesEntity`, `ProviderCompletionEntity`
(under `src/domain/entities/`).

## API Dependencies

- `PATCH service-provider/settings` (returns `204`; sent fields merged into the
  in-memory entity, not re-fetched).
- `PUT service-provider/working-hours` (returns the persisted schedule).
- `GET /settings`, `GET service-provider/working-hours`,
  `GET service-provider/completion`, `GET /categories`.

## External Integrations

Category catalog via the `services` package; media upload via `media_upload`;
document flow via `document_flow`.

## Business Rules

- Completion and working-hours are **owner-only** backend surfaces — the bloc
  skips those two fetches for non-owner (worker/manager) tokens (RBAC Phase 7).
- Business description max length is **350** chars.
- On a failed description save, the attempted text is preserved
  (`pendingDescription`) and re-seeds the edit sheet on retry (SAN-567).
- Working hours may have **multiple slots per day** (split shifts); slots are
  grouped back into one `WorkingHoursDayEntity` per day on save (SAN-568).
- Saved times display in 12-hour AM/PM via `BranchScheduleFormatter`
  (`DateFormat('h:mm a')`, locale-aware ص/م in Arabic) (SAN-568).

## Important Constraints

- Save failures must show `failure.localizedMessage()`, not raw `.message`
  (which may be an i18n key like `errors.timeout`) (SAN-567).

## Known Edge Cases

- Timed-out `PATCH` is not auto-retried (non-idempotent); the user retries.
- A description never previously set renders empty if lost — mitigated by the
  `pendingDescription` draft.

## Known Issues

- The ~60s save-timeout symptom noted in SAN-567 was left as a
  backend/token-refresh concern; the client change only fixed messaging + draft
  preservation.

## Relevant Source Files

- `presentation/pages/general_settings_page.dart`
- `presentation/bloc/organization_settings/organization_settings_bloc.dart`
- `presentation/bloc/organization_settings/organization_settings_state.dart`
- `presentation/widgets/bottom_sheets/edit_working_hours_bottom_sheet.dart`
- `src/module/organization_settings_module.dart`
- `apps/sanad_provider/packages/branches/lib/src/presentation/utils/branch_schedule_formatter.dart`

## Related Documentation

[`../ARCHITECTURE_BLUEPRINT.md`](../ARCHITECTURE_BLUEPRINT.md) ·
[`../../.claude/rules/state-management.md`](../../.claude/rules/state-management.md) ·
[`../../.claude/rules/localization.md`](../../.claude/rules/localization.md)
