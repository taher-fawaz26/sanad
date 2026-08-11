import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/domain/repositories/location_repository.dart';
import 'package:maps/src/services/location_service.dart';

/// Reads the current location-permission state without prompting the user.
///
/// Used to decide whether the map's MyLocation layer can be safely enabled —
/// never call this expecting it to request permission (see
/// [GetCurrentLocationUseCase] for the requesting flow).
class CheckLocationPermissionUseCase
    implements UseCase<LocationPermissionStatus, NoParams> {
  const CheckLocationPermissionUseCase(this._repository);

  final LocationRepository _repository;

  @override
  TaskEither<Failure, LocationPermissionStatus> call(NoParams params) {
    return TaskEither.tryCatch(
      _repository.checkPermission,
      (error, _) => UnknownFailure(message: error.toString()),
    );
  }
}
