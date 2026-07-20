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
    this.email,
    this.phone,
    this.branchId,
  });

  final String fullName;
  final String jobTitle;
  final WorkerType type;
  final String? email;
  final String? phone;
  final String? branchId;

  @override
  List<Object?> get props => [fullName, jobTitle, type, email, phone, branchId];
}

class InviteWorkerUseCase implements UseCase<Unit, InviteWorkerParams> {
  const InviteWorkerUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, Unit> call(InviteWorkerParams params) =>
      _repository.inviteWorker(params);
}
