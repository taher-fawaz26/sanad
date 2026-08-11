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
