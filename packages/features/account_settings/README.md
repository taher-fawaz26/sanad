# account_settings

Shared account settings feature for `sanad_provider` and `sanad_client`.

## Current scope

- Account Settings hub page
- Logout (via `AuthBloc`)

## Future screens (placeholders only)

Profile, Edit Profile, Change Password, Security, Notification Preferences,
Language, Delete Account.

## Usage

1. Add `AccountSettingsModule()` to the app `ModuleRegistry`.
2. Navigate with `AccountSettingsRoutes.hub` (`/settings/account`).
