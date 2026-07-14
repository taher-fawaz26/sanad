import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/repositories/geocoding_repository.dart';

class NearbyAreasParams extends Equatable {
  const NearbyAreasParams({
    required this.center,
    required this.radiusKm,
    this.localeIdentifier,
  });

  final LatLng center;
  final double radiusKm;
  final String? localeIdentifier;

  @override
  List<Object?> get props => [center, radiusKm, localeIdentifier];
}

class GetNearbyAreasUseCase
    implements UseCase<List<String>, NearbyAreasParams> {
  const GetNearbyAreasUseCase(this._repository);

  final GeocodingRepository _repository;

  @override
  TaskEither<Failure, List<String>> call(NearbyAreasParams params) =>
      _repository.nearbyAreaNames(
        center: params.center,
        radiusKm: params.radiusKm,
        localeIdentifier: params.localeIdentifier,
      );
}
