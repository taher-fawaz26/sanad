import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/domain/repositories/places_repository.dart';

class SearchPlacesParams extends Equatable {
  const SearchPlacesParams({
    required this.query,
    this.language,
    this.biasLocation,
  });

  final String query;
  final String? language;
  final LatLng? biasLocation;

  @override
  List<Object?> get props => [query, language, biasLocation];
}

class SearchPlacesUseCase
    implements UseCase<List<PlacePrediction>, SearchPlacesParams> {
  const SearchPlacesUseCase(this._repository);

  final PlacesRepository _repository;

  @override
  TaskEither<Failure, List<PlacePrediction>> call(
    SearchPlacesParams params,
  ) => _repository.searchPlaces(
    query: params.query,
    language: params.language,
    biasLocation: params.biasLocation,
  );
}
