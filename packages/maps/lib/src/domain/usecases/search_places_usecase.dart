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
    this.types,
  });

  final String query;
  final String? language;
  final LatLng? biasLocation;

  /// Restricts predictions to a Google Autocomplete type collection, e.g.
  /// `'(regions)'` to exclude businesses/POIs and only return geographic
  /// areas. Null keeps the default (unrestricted) behavior.
  final String? types;

  @override
  List<Object?> get props => [query, language, biasLocation, types];
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
    types: params.types,
  );
}
