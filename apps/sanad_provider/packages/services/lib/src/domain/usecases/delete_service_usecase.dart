import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/repositories/services_repository.dart';

class DeleteServiceUseCase implements UseCase<Unit, String> {
  const DeleteServiceUseCase(this._repository);

  final ServicesRepository _repository;

  @override
  TaskEither<Failure, Unit> call(String id) => _repository.deleteService(id);
}
