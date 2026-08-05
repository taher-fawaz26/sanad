# account_settings

Shared account settings feature for `sanad_provider` and `sanad_client`.

## Current scope

- Account Settings page (Figma `3821:18875`)
- Account credentials, language preferences, help & support sections
- Language preferences sheet with single-select [AppRadio] (`3821:19032`)
- Delete account confirmation popover (`3821:19091`) via [AuthBloc]

## Usage

1. Add `AccountSettingsModule()` to the app `ModuleRegistry`.
2. Navigate with `AccountSettingsRoutes.hub` (`/settings/account`).
