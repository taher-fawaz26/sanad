import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/domain/entities/city_entity.dart';
import 'package:maps/src/domain/entities/country_entity.dart';

abstract interface class LocationsRepository {
  TaskEither<Failure, List<CountryEntity>> getCountries();

  TaskEither<Failure, List<CityEntity>> getCities({
    required String countryId,
  });
}
