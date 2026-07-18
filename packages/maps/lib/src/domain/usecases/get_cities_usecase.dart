import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/domain/entities/city_entity.dart';
import 'package:maps/src/domain/failures/locations_failure.dart';
import 'package:maps/src/domain/repositories/locations_repository.dart';

/// Resolves the single supported country automatically, then fetches its
/// cities.
///
/// - 0 countries returned  → [LocationsNoCountryFailure]
/// - 1 country returned    → cities are fetched and returned
/// - >1 countries returned → [LocationsMultiCountryFailure] (no picker yet)
class GetCitiesUseCase implements UseCase<List<CityEntity>, NoParams> {
  const GetCitiesUseCase(this._repository);

  final LocationsRepository _repository;

  @override
  TaskEither<Failure, List<CityEntity>> call(NoParams params) =>
      _repository.getCountries().flatMap((countries) {
        if (countries.isEmpty) {
          return TaskEither.left(const LocationsNoCountryFailure());
        }
        if (countries.length > 1) {
          return TaskEither.left(const LocationsMultiCountryFailure());
        }
        return _repository.getCities(countryId: countries.first.id);
      });
}
