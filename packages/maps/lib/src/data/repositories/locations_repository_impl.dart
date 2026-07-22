import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/data/endpoints/location_api_paths.dart';
import 'package:maps/src/data/models/area_dto.dart';
import 'package:maps/src/data/models/city_dto.dart';
import 'package:maps/src/data/models/country_dto.dart';
import 'package:maps/src/domain/entities/area_entity.dart';
import 'package:maps/src/domain/entities/city_entity.dart';
import 'package:maps/src/domain/entities/country_entity.dart';
import 'package:maps/src/domain/repositories/locations_repository.dart';
import 'package:network/network.dart';

class LocationsRepositoryImpl implements LocationsRepository {
  LocationsRepositoryImpl(this._apiClient);

  final BaseApiClient _apiClient;

  final Map<String, List<AreaEntity>> _areasCache = {};

  /// Shares a single in-flight pagination per city. Without this, concurrent
  /// callers (e.g. the initial resolve and a camera-move resolve firing before
  /// the first completes) would each walk all pages because the cache is only
  /// populated once a full run finishes.
  final Map<String, Future<Either<Failure, List<AreaEntity>>>> _areasInFlight =
      {};

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

  @override
  TaskEither<Failure, List<AreaEntity>> getAreasByCity({
    required String cityId,
  }) {
    return TaskEither(() {
      final cached = _areasCache[cityId];
      if (cached != null) {
        return Future.value(Either.right(cached));
      }

      return _areasInFlight[cityId] ??=
          _fetchAllAreaPages(
            cityId: cityId,
            page: 1,
            accumulated: [],
          ).run().then((either) {
            _areasInFlight.remove(cityId);
            return either.map((areas) {
              _areasCache[cityId] = areas;
              return areas;
            });
          });
    });
  }

  TaskEither<Failure, List<AreaEntity>> _fetchAllAreaPages({
    required String cityId,
    required int page,
    required List<AreaEntity> accumulated,
  }) => _apiClient
      .request<_AreaPageResult>(
        path: LocationApiPaths.areas,
        method: RequestMethod.get,
        query: {
          'cityId': cityId,
          'page': '$page',
        },
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final items = (json['data'] as List<dynamic>)
              .map(
                (e) => AreaDto.fromJson(e as Map<String, dynamic>).toDomain(),
              )
              .toList();
          final meta = json['meta'] as Map<String, dynamic>;
          final totalPages = meta['totalPages'] as int? ?? 1;
          final currentPage = meta['currentPage'] as int? ?? page;
          return _AreaPageResult(
            items: items,
            hasMore: currentPage < totalPages,
          );
        },
      )
      .flatMap(
        (result) {
          final all = [...accumulated, ...result.items];
          if (!result.hasMore) return TaskEither.right(all);
          return _fetchAllAreaPages(
            cityId: cityId,
            page: page + 1,
            accumulated: all,
          );
        },
      );
}

class _AreaPageResult {
  const _AreaPageResult({required this.items, required this.hasMore});
  final List<AreaEntity> items;
  final bool hasMore;
}
