import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/repositories/location_repository.dart';

class GetCurrentLocationUseCase implements UseCase<LatLng, NoParams> {
  const GetCurrentLocationUseCase(this._repository);

  final LocationRepository _repository;

  @override
  TaskEither<Failure, LatLng> call(NoParams params) =>
      _repository.getCurrentLocation();
}
