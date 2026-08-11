part of 'worker_roles_bloc.dart';

class WorkerRolesState extends Equatable {
  const WorkerRolesState({
    this.status = RequestStatus.initial,
    this.roles = const [],
    this.catalogStatus = RequestStatus.initial,
    this.catalog = const [],
    this.mutationStatus = RequestStatus.initial,
    this.failure,
  });

  final RequestStatus status;
  final List<RoleEntity> roles;

  /// Full role catalog, loaded on-demand for the "manage roles" sheet.
  final RequestStatus catalogStatus;
  final List<RoleEntity> catalog;

  /// Status of the last assign/remove mutation.
  final RequestStatus mutationStatus;
  final Failure? failure;

  bool get isLoading => status == RequestStatus.loading;
  bool get isMutating => mutationStatus == RequestStatus.loading;

  WorkerRolesState copyWith({
    RequestStatus? status,
    List<RoleEntity>? roles,
    RequestStatus? catalogStatus,
    List<RoleEntity>? catalog,
    RequestStatus? mutationStatus,
    Failure? failure,
  }) => WorkerRolesState(
    status: status ?? this.status,
    roles: roles ?? this.roles,
    catalogStatus: catalogStatus ?? this.catalogStatus,
    catalog: catalog ?? this.catalog,
    mutationStatus: mutationStatus ?? this.mutationStatus,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    roles,
    catalogStatus,
    catalog,
    mutationStatus,
    failure,
  ];
}
