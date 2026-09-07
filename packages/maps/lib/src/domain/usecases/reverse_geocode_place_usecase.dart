import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/geocoded_address.dart';
import 'package:maps/src/domain/repositories/reverse_geocode_place_repository.dart';

class ReverseGeocodePlaceParams extends Equatable {
  const ReverseGeocodePlaceParams({
    required this.position,
    this.localeIdentifier,
  });

  final LatLng position;
  final String? localeIdentifier;

  @override
  List<Object?> get props => [position, localeIdentifier];
}

/// Reverse-geocodes a coordinate to a [GeocodedAddress] carrying a Google
/// `place_id` (via the REST Geocoding API). Returns `null` inside the right
/// channel when Google has no result for the coordinate.
class ReverseGeocodePlaceUseCase
    implements UseCase<GeocodedAddress?, ReverseGeocodePlaceParams> {
  const ReverseGeocodePlaceUseCase(this._repository);

  final ReverseGeocodePlaceRepository _repository;

  @override
  TaskEither<Failure, GeocodedAddress?> call(
    ReverseGeocodePlaceParams params,
  ) => _repository.reverseGeocodePlace(
    position: params.position,
    languageCode: params.localeIdentifier,
  );
}
