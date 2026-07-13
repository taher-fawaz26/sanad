import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/service_entity.dart';
import 'package:services/src/domain/repositories/service_repository.dart';

class GetServicesUseCase implements UseCase<List<ServiceEntity>, NoParams> {
  const GetServicesUseCase(this._repository);

  final ServiceRepository _repository;

  @override
  TaskEither<Failure, List<ServiceEntity>> call(NoParams params) =>
      _repository.getServices();
}
