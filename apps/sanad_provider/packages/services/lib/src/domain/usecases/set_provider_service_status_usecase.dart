import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';

class SetProviderServiceStatusParams extends Equatable {
  const SetProviderServiceStatusParams({
    required this.id,
    required this.status,
  });

  final String id;
  final ProviderServiceStatus status;

  @override
  List<Object?> get props => [id, status];
}

class SetProviderServiceStatusUseCase
    implements UseCase<ProviderServiceEntity, SetProviderServiceStatusParams> {
  const SetProviderServiceStatusUseCase(this._repository);

  final ProviderServicesRepository _repository;

  @override
  TaskEither<Failure, ProviderServiceEntity> call(
    SetProviderServiceStatusParams params,
  ) => _repository.updateProviderServiceStatus(
    id: params.id,
    status: params.status,
  );
}
