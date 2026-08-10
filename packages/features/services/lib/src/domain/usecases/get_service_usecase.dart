import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/domain/repositories/services_repository.dart';

class GetServiceUseCase implements UseCase<ServiceRecordEntity, String> {
  const GetServiceUseCase(this._repository);

  final ServicesRepository _repository;

  @override
  TaskEither<Failure, ServiceRecordEntity> call(String id) =>
      _repository.getService(id);
}
