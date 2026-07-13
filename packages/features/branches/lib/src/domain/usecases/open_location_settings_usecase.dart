import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/maps.dart';

class OpenLocationSettingsUseCase implements UseCase<bool, NoParams> {
  const OpenLocationSettingsUseCase(this._locationService);

  final LocationService _locationService;

  @override
  TaskEither<Failure, bool> call(NoParams params) {
    return TaskEither.tryCatch(
      _locationService.openAppSettings,
      (error, _) => UnknownFailure(message: error.toString()),
    );
  }
}
