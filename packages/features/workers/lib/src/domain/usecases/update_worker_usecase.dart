import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';

class UpdateWorkerParams extends Equatable {
  const UpdateWorkerParams({
    required this.id,
    required this.fullName,
    required this.jobTitle,
    required this.type,
    this.email,
    this.phone,
    this.branchId,
  });

  final String id;
  final String fullName;
  final String jobTitle;
  final WorkerType type;
  final String? email;
  final String? phone;
  final String? branchId;

  @override
  List<Object?> get props => [
    id,
    fullName,
    jobTitle,
    type,
    email,
    phone,
    branchId,
  ];
}

class UpdateWorkerUseCase implements UseCase<WorkerEntity, UpdateWorkerParams> {
  const UpdateWorkerUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, WorkerEntity> call(UpdateWorkerParams params) =>
      _repository.updateWorker(params);
}
