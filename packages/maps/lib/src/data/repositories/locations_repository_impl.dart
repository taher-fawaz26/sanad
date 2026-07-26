import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/data/endpoints/location_api_paths.dart';
import 'package:maps/src/data/models/city_dto.dart';
import 'package:maps/src/data/models/country_dto.dart';
import 'package:maps/src/domain/entities/city_entity.dart';
import 'package:maps/src/domain/entities/country_entity.dart';
import 'package:maps/src/domain/repositories/locations_repository.dart';
import 'package:network/network.dart';

class LocationsRepositoryImpl implements LocationsRepository {
  LocationsRepositoryImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, List<CountryEntity>> getCountries() =>
      _apiClient.request<List<CountryEntity>>(
        path: LocationApiPaths.countries,
        method: RequestMethod.get,
        parser: (data) => (data as List<dynamic>)
            .map(
              (e) => CountryDto.fromJson(e as Map<String, dynamic>).toDomain(),
            )
            .toList(),
      );

  @override
  TaskEither<Failure, List<CityEntity>> getCities({
    required String countryId,
  }) => _apiClient.request<List<CityEntity>>(
    path: LocationApiPaths.cities,
    method: RequestMethod.get,
    query: {'countryId': countryId},
    parser: (data) => (data as List<dynamic>)
        .map((e) => CityDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList(),
  );
}
