import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';

class InviteWorkerParams extends Equatable {
  const InviteWorkerParams({
    required this.fullName,
    required this.jobTitle,
    required this.type,
    required this.email,
    required this.phone,
    required this.roleIds,
  });

  final String fullName;
  final String jobTitle;
  final WorkerType type;

  /// Required by the backend `CreateInvitationDto`.
  final String email;

  /// Required by the backend `CreateInvitationDto` (E.164, `+971…`).
  final String phone;

  /// Role ids granted on acceptance — must include at least the mandatory
  /// baseline role for [type] (see `RoleAssignmentPolicy` in `provider_rbac`).
  /// The backend also re-applies that baseline server-side, but the client
  /// still sends it explicitly so the invite reflects what the admin saw.
  final List<String> roleIds;

  @override
  List<Object?> get props => [fullName, jobTitle, type, email, phone, roleIds];
}

class InviteWorkerUseCase implements UseCase<Unit, InviteWorkerParams> {
  const InviteWorkerUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, Unit> call(InviteWorkerParams params) =>
      _repository.inviteWorker(params);
}
