import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/maps.dart';

class SearchLocationParams extends Equatable {
  const SearchLocationParams({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

class SearchLocationUseCase implements UseCase<LatLng, SearchLocationParams> {
  const SearchLocationUseCase(this._geocodingService);

  final GeocodingService _geocodingService;

  @override
  TaskEither<Failure, LatLng> call(SearchLocationParams params) =>
      _geocodingService.coordinatesFromAddress(params.query);
}
