import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/domain/repositories/services_repository.dart';

class UpdateServiceStatusParams extends Equatable {
  const UpdateServiceStatusParams({required this.id, required this.isActive});

  final String id;
  final bool isActive;

  @override
  List<Object?> get props => [id, isActive];
}

class UpdateServiceStatusUseCase
    implements UseCase<ServiceRecordEntity, UpdateServiceStatusParams> {
  const UpdateServiceStatusUseCase(this._repository);

  final ServicesRepository _repository;

  @override
  TaskEither<Failure, ServiceRecordEntity> call(
    UpdateServiceStatusParams params,
  ) => _repository.updateServiceStatus(
    id: params.id,
    isActive: params.isActive,
  );
}
