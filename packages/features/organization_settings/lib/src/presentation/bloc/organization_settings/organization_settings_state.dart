part of 'organization_settings_bloc.dart';

class OrganizationSettingsState extends Equatable {
  const OrganizationSettingsState({
    this.status = RequestStatus.initial,
    this.organization,
    this.failure,
  });

  final RequestStatus status;

  /// The single root entity every section reads from. Null until the first
  /// successful load.
  final OrganizationSettingsEntity? organization;
  final Failure? failure;

  OrganizationSettingsState copyWith({
    RequestStatus? status,
    OrganizationSettingsEntity? organization,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return OrganizationSettingsState(
      status: status ?? this.status,
      organization: organization ?? this.organization,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, organization, failure];
}
