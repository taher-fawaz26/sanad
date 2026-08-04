# organization_settings

Provider-only organization settings feature.

## Current scope

- Organization KPI hub (General Settings, Team, Branches, Invitations)
- Settings menu sheet (Organization / Account entry)
- General Settings empty placeholder

## Future screens (placeholders only)

Organization Information, Business Details, Working Hours, Branch
Configuration, Tax Information, Commercial Registration, Bank Account,
Service Areas.

## Usage

1. Add `OrganizationSettingsModule()` to the provider `ModuleRegistry`.
2. Host the hub in the provider shell at `OrganizationSettingsRoutes.hub`.
3. Open the menu with `showSettingsMenuSheet(context)`.
