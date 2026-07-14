import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/geocoded_address.dart';
import 'package:maps/src/domain/repositories/geocoding_repository.dart';

class ReverseGeocodeParams extends Equatable {
  const ReverseGeocodeParams({
    required this.position,
    this.localeIdentifier,
  });

  final LatLng position;
  final String? localeIdentifier;

  @override
  List<Object?> get props => [position, localeIdentifier];
}

class ReverseGeocodeUseCase
    implements UseCase<GeocodedAddress, ReverseGeocodeParams> {
  const ReverseGeocodeUseCase(this._repository);

  final GeocodingRepository _repository;

  @override
  TaskEither<Failure, GeocodedAddress> call(ReverseGeocodeParams params) =>
      _repository.reverseGeocode(
        params.position,
        localeIdentifier: params.localeIdentifier,
      );
}
