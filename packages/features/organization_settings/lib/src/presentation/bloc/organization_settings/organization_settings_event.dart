part of 'organization_settings_bloc.dart';

sealed class OrganizationSettingsEvent extends Equatable {
  const OrganizationSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load — fetches the organization's full settings profile.
final class OrganizationSettingsLoaded extends OrganizationSettingsEvent {
  const OrganizationSettingsLoaded();
}

/// Re-fetches the organization's full settings profile (e.g. pull-to-refresh).
final class OrganizationSettingsRefreshed extends OrganizationSettingsEvent {
  const OrganizationSettingsRefreshed();
}
