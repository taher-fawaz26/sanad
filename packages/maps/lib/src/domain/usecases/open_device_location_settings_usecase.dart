import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/domain/repositories/location_repository.dart';

/// Opens the OS *device location* settings (the global GPS toggle).
///
/// Distinct from [OpenLocationSettingsUseCase], which opens the app's own
/// settings page (the recovery path for a permanently-denied app permission).
/// This is the recovery path when location *services* are switched off — the
/// app permission screen cannot turn the device radio on.
class OpenDeviceLocationSettingsUseCase implements UseCase<bool, NoParams> {
  const OpenDeviceLocationSettingsUseCase(this._repository);

  final LocationRepository _repository;

  @override
  TaskEither<Failure, bool> call(NoParams params) {
    return TaskEither.tryCatch(
      _repository.openLocationSettings,
      (error, _) => UnknownFailure(message: error.toString()),
    );
  }
}
