import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/domain/entities/city_entity.dart';
import 'package:maps/src/domain/failures/locations_failure.dart';
import 'package:maps/src/domain/repositories/locations_repository.dart';

/// Resolves the supported country automatically, then fetches its cities.
///
/// - 0 countries returned → [LocationsNoCountryFailure]
/// - ≥1 countries returned → cities for [List.first] are fetched and returned
class GetCitiesUseCase implements UseCase<List<CityEntity>, NoParams> {
  const GetCitiesUseCase(this._repository);

  final LocationsRepository _repository;

  @override
  TaskEither<Failure, List<CityEntity>> call(NoParams params) =>
      _repository.getCountries().flatMap((countries) {
        if (countries.isEmpty) {
          return TaskEither.left(const LocationsNoCountryFailure());
        }

        // Product decision:
        // The Provider application currently operates only in the UAE.
        // If multiple country records are returned by the backend,
        // always use the first country and continue loading cities.
        // Multi-country support will be implemented in the future.
        final country = countries.first;
        return _repository.getCities(countryId: country.id);
      });
}
