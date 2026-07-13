import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/maps.dart';

class ReverseGeocodeParams extends Equatable {
  const ReverseGeocodeParams({required this.position});

  final LatLng position;

  @override
  List<Object?> get props => [position];
}

class ReverseGeocodeUseCase implements UseCase<String, ReverseGeocodeParams> {
  const ReverseGeocodeUseCase(this._geocodingService);

  final GeocodingService _geocodingService;

  @override
  TaskEither<Failure, String> call(ReverseGeocodeParams params) =>
      _geocodingService.addressFromCoordinates(params.position);
}
