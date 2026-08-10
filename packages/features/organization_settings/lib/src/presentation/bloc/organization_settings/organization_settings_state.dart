part of 'organization_settings_bloc.dart';

class OrganizationSettingsState extends Equatable {
  const OrganizationSettingsState({
    this.status = RequestStatus.initial,
    this.organization,
    this.failure,
    this.workingHours = const [],
    this.completion,
    this.categoryCatalog = const [],
    this.saveStatus = RequestStatus.initial,
    this.saveFailure,
  });

  final RequestStatus status;

  /// The single root entity every section reads from. Null until the first
  /// successful load.
  final OrganizationProfileEntity? organization;
  final Failure? failure;

  /// The organization's weekly schedule — `service-provider/working-hours`.
  /// Empty means no hours configured.
  final List<WorkingHoursDayEntity> workingHours;

  /// `GET service-provider/completion` — null until the first successful
  /// fetch. Optional: a failure here does not fail the whole page load.
  final ProviderCompletionEntity? completion;

  /// The full category catalog (`GET /categories`) used to drive the
  /// category picker — distinct from [OrganizationProfileEntity.categories]
  /// (the organization's already-selected subset).
  final List<CategoryEntity> categoryCatalog;

  /// Status of the most recent settings/working-hours mutation
  /// (description, categories, social profiles, working hours).
  final RequestStatus saveStatus;
  final Failure? saveFailure;

  OrganizationSettingsState copyWith({
    RequestStatus? status,
    OrganizationProfileEntity? organization,
    Failure? failure,
    bool clearFailure = false,
    List<WorkingHoursDayEntity>? workingHours,
    ProviderCompletionEntity? completion,
    List<CategoryEntity>? categoryCatalog,
    RequestStatus? saveStatus,
    Failure? saveFailure,
    bool clearSaveFailure = false,
  }) {
    return OrganizationSettingsState(
      status: status ?? this.status,
      organization: organization ?? this.organization,
      failure: clearFailure ? null : (failure ?? this.failure),
      workingHours: workingHours ?? this.workingHours,
      completion: completion ?? this.completion,
      categoryCatalog: categoryCatalog ?? this.categoryCatalog,
      saveStatus: saveStatus ?? this.saveStatus,
      saveFailure: clearSaveFailure ? null : (saveFailure ?? this.saveFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    organization,
    failure,
    workingHours,
    completion,
    categoryCatalog,
    saveStatus,
    saveFailure,
  ];
}
