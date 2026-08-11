part of 'roles_list_bloc.dart';

class RolesListState extends Equatable {
  const RolesListState({
    this.status = RequestStatus.initial,
    this.roles = const [],
    this.failure,
  });

  final RequestStatus status;
  final List<RoleEntity> roles;
  final Failure? failure;

  bool get isLoading => status == RequestStatus.loading;
  bool get hasError => status == RequestStatus.failure;

  RolesListState copyWith({
    RequestStatus? status,
    List<RoleEntity>? roles,
    Failure? failure,
  }) => RolesListState(
    status: status ?? this.status,
    roles: roles ?? this.roles,
    failure: failure ?? this.failure,
  );

  @override
  List<Object?> get props => [status, roles, failure];
}
