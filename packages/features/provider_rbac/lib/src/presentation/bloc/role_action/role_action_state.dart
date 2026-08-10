part of 'role_action_bloc.dart';

enum RoleActionStatus { idle, inProgress, success, failure }

class RoleActionState extends Equatable {
  const RoleActionState({
    this.status = RoleActionStatus.idle,
    this.roleId,
    this.failure,
  });

  final RoleActionStatus status;

  /// The role the last action was performed against.
  final String? roleId;
  final Failure? failure;

  bool get isInProgress => status == RoleActionStatus.inProgress;

  RoleActionState copyWith({
    RoleActionStatus? status,
    String? roleId,
    Failure? failure,
  }) => RoleActionState(
    status: status ?? this.status,
    roleId: roleId ?? this.roleId,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, roleId, failure];
}
