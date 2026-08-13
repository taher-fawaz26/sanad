part of 'organization_settings_bloc.dart';

sealed class OrganizationSettingsEvent extends Equatable {
  const OrganizationSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load — fetches the organization's full settings profile, its
/// working hours, its profile-completion checklist, and the category
/// catalog to drive the category picker.
final class OrganizationSettingsLoaded extends OrganizationSettingsEvent {
  const OrganizationSettingsLoaded();
}

/// Re-fetches everything (e.g. pull-to-refresh, or after editing legal
/// documents).
final class OrganizationSettingsRefreshed extends OrganizationSettingsEvent {
  const OrganizationSettingsRefreshed();
}

/// Saves a new business description — `PATCH service-provider/settings`.
final class OrganizationSettingsDescriptionSaved
    extends OrganizationSettingsEvent {
  const OrganizationSettingsDescriptionSaved(this.description);

  final String description;

  @override
  List<Object?> get props => [description];
}

/// Saves the selected categories — `PATCH service-provider/settings`.
///
/// [categories] must be real backend categories (from the category
/// catalog), never local/mock entries — their `id`s are sent as
/// `categoryIds` and the full entities are merged back into state locally
/// afterwards (the PATCH itself returns `204 No Content`).
final class OrganizationSettingsCategoriesSaved
    extends OrganizationSettingsEvent {
  const OrganizationSettingsCategoriesSaved(this.categories);

  final List<CategoryEntity> categories;

  @override
  List<Object?> get props => [categories];
}

/// Saves social profile links — `PATCH service-provider/settings`.
final class OrganizationSettingsSocialProfilesSaved
    extends OrganizationSettingsEvent {
  const OrganizationSettingsSocialProfilesSaved(this.socialProfiles);

  final SocialProfilesEntity socialProfiles;

  @override
  List<Object?> get props => [socialProfiles];
}

/// Saves the weekly working-hours schedule — `PUT
/// service-provider/working-hours`. Send an empty list to clear all hours.
final class OrganizationSettingsWorkingHoursSaved
    extends OrganizationSettingsEvent {
  const OrganizationSettingsWorkingHoursSaved(this.availability);

  final List<WorkingHoursDayEntity> availability;

  @override
  List<Object?> get props => [availability];
}

/// A cover/logo upload succeeded in [IdentityHeaderBloc] — merges the new
/// URL into [OrganizationSettingsState.organization] so the change survives
/// a subsequent full reload (and, once cached, doesn't get overwritten by a
/// stale cached value). The upload itself already happened; this only syncs
/// local state, so it carries no request status of its own.
final class OrganizationSettingsMediaUpdated extends OrganizationSettingsEvent {
  const OrganizationSettingsMediaUpdated({
    required this.slot,
    required this.url,
  });

  final OrganizationMediaSlot slot;
  final String url;

  @override
  List<Object?> get props => [slot, url];
}
