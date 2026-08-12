import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';

class DeleteProviderServiceUseCase implements UseCase<Unit, String> {
  const DeleteProviderServiceUseCase(this._repository);

  final ProviderServicesRepository _repository;

  @override
  TaskEither<Failure, Unit> call(String id) =>
      _repository.deleteProviderService(id);
}
