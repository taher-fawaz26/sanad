import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/domain/repositories/location_repository.dart';

class OpenLocationSettingsUseCase implements UseCase<bool, NoParams> {
  const OpenLocationSettingsUseCase(this._repository);

  final LocationRepository _repository;

  @override
  TaskEither<Failure, bool> call(NoParams params) {
    return TaskEither.tryCatch(
      _repository.openAppSettings,
      (error, _) => UnknownFailure(message: error.toString()),
    );
  }
}
