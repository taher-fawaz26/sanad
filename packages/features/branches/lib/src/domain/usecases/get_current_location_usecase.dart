import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/maps.dart';

class GetCurrentLocationUseCase implements UseCase<LatLng, NoParams> {
  const GetCurrentLocationUseCase(this._locationService);

  final LocationService _locationService;

  @override
  TaskEither<Failure, LatLng> call(NoParams params) =>
      _locationService.getCurrentLocation();
}
