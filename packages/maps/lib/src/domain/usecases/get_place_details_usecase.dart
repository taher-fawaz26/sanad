import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/repositories/places_repository.dart';

class GetPlaceDetailsParams extends Equatable {
  const GetPlaceDetailsParams({required this.placeId});

  final String placeId;

  @override
  List<Object?> get props => [placeId];
}

class GetPlaceDetailsUseCase implements UseCase<LatLng, GetPlaceDetailsParams> {
  const GetPlaceDetailsUseCase(this._repository);

  final PlacesRepository _repository;

  @override
  TaskEither<Failure, LatLng> call(GetPlaceDetailsParams params) =>
      _repository.getPlaceCoordinates(placeId: params.placeId);
}
