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
    this.phone,
  });

  final String id;
  final String fullName;
  final String jobTitle;
  final WorkerType type;

  /// Optional in the backend `UpdateWorkerDto`. Email is not server-editable,
  /// so it is intentionally absent here.
  final String? phone;

  @override
  List<Object?> get props => [id, fullName, jobTitle, type, phone];
}

class UpdateWorkerUseCase implements UseCase<WorkerEntity, UpdateWorkerParams> {
  const UpdateWorkerUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, WorkerEntity> call(UpdateWorkerParams params) =>
      _repository.updateWorker(params);
}
