part of 'account_settings_bloc.dart';

sealed class AccountSettingsEvent extends Equatable {
  const AccountSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load — fetches account settings for the hub.
final class AccountSettingsLoaded extends AccountSettingsEvent {
  const AccountSettingsLoaded();
}

/// Re-fetches account settings after an external change.
final class AccountSettingsRefreshed extends AccountSettingsEvent {
  const AccountSettingsRefreshed();
}

/// Persists a partial update (`PATCH account-settings`).
final class AccountSettingsUpdated extends AccountSettingsEvent {
  const AccountSettingsUpdated(this.params);

  final UpdateAccountSettingsParams params;

  @override
  List<Object?> get props => [params];
}

/// Syncs the account's `preferredLanguage` to the backend after the user has
/// already switched the app language locally.
///
/// Deliberately separate from [AccountSettingsUpdated]: the app language is a
/// device preference that applies immediately, so this sync must not show a
/// blocking progress dialog, must not gate the language change on a 200, and
/// must not be rolled back on failure. It only keeps backend-generated content
/// (emails, notifications) on the same language.
final class AccountSettingsLanguageSynced extends AccountSettingsEvent {
  const AccountSettingsLanguageSynced(this.language);

  final PreferredLanguage language;

  @override
  List<Object?> get props => [language];
}
