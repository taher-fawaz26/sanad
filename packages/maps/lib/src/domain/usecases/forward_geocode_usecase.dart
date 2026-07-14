import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/repositories/geocoding_repository.dart';

class ForwardGeocodeParams extends Equatable {
  const ForwardGeocodeParams({
    required this.address,
    this.localeIdentifier,
  });

  final String address;
  final String? localeIdentifier;

  @override
  List<Object?> get props => [address, localeIdentifier];
}

class ForwardGeocodeUseCase
    implements UseCase<LatLng, ForwardGeocodeParams> {
  const ForwardGeocodeUseCase(this._repository);

  final GeocodingRepository _repository;

  @override
  TaskEither<Failure, LatLng> call(ForwardGeocodeParams params) =>
      _repository.forwardGeocode(
        params.address,
        localeIdentifier: params.localeIdentifier,
      );
}
