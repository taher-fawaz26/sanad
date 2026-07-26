import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/domain/failures/places_failure.dart';
import 'package:maps/src/domain/repositories/nearby_areas_repository.dart';
import 'package:maps/src/presentation/utils/geo_math.dart';

/// Derives serving areas within a coverage radius directly from Google.
///
/// There is no Google API that lists neighborhoods inside a radius (Nearby
/// Search does not support `neighborhood`/`sublocality` types), so this
/// reverse-geocodes the center plus a ring of sample points and collects the
/// distinct neighborhoods, each with its real Google `place_id`.
class GoogleNearbyAreasRepositoryImpl implements NearbyAreasRepository {
  GoogleNearbyAreasRepositoryImpl({
    required String apiKey,
    required Dio dio,
    String countryCode = 'ae',
  }) : _apiKey = apiKey,
       _dio = dio,
       _countryCode = countryCode;

  final String _apiKey;
  final Dio _dio;

  /// ISO 3166-1 alpha-2 country that returned areas must belong to. Areas
  /// outside it are dropped so the user can never cover a place abroad.
  final String _countryCode;

  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  /// Neighborhood/sublocality granularity — the "areas" the product means.
  static const _resultType = 'neighborhood|sublocality';

  /// Bearings (degrees, 0 = north) sampled on the ring around the center.
  static const _ringBearings = <double>[0, 60, 120, 180, 240, 300];

  /// Ring radius as a fraction of the coverage radius. Kept modest (one ring)
  /// so a single resolve stays around 7 geocoding calls.
  static const _ringFraction = 0.66;

  @override
  TaskEither<Failure, List<ServingArea>> resolveNearbyAreas({
    required LatLng center,
    required double radiusKm,
    String? languageCode,
  }) {
    return TaskEither(() async {
      final samples = _samplePoints(center: center, radiusKm: radiusKm);

      final outcomes = await Future.wait(
        samples.map(
          (point) => _reverseGeocode(point, languageCode: languageCode),
        ),
      );

      final areasByPlaceId = <String, ServingArea>{};
      Failure? firstFailure;
      var anySuccess = false;

      for (final outcome in outcomes) {
        outcome.match(
          (failure) => firstFailure ??= failure,
          (areas) {
            anySuccess = true;
            for (final area in areas) {
              final within =
                  GeoMath.distanceKm(center, area.latLng) <= radiusKm;
              if (within) {
                areasByPlaceId.putIfAbsent(area.placeId, () => area);
              }
            }
          },
        );
      }

      // Only fail the whole resolve when every sample errored. A partial set of
      // successes is still useful, and a single flaky sample must not blank the
      // coverage list.
      if (!anySuccess && firstFailure != null) {
        return Either.left(firstFailure!);
      }

      return Either.right(areasByPlaceId.values.toList(growable: false));
    });
  }

  List<LatLng> _samplePoints({
    required LatLng center,
    required double radiusKm,
  }) {
    if (radiusKm <= 0) return [center];
    final ringDistance = radiusKm * _ringFraction;
    return [
      center,
      for (final bearing in _ringBearings)
        GeoMath.offsetByKm(
          center,
          distanceKm: ringDistance,
          bearingDegrees: bearing,
        ),
    ];
  }

  Future<Either<Failure, List<ServingArea>>> _reverseGeocode(
    LatLng point, {
    String? languageCode,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _geocodeUrl,
        queryParameters: <String, String>{
          'latlng': '${point.latitude},${point.longitude}',
          'key': _apiKey,
          'result_type': _resultType,
          'region': _countryCode,
          if (_language(languageCode) case final lang?) 'language': lang,
        },
      );
      final json = response.data!;
      final status = json['status'] as String;
      if (status == 'ZERO_RESULTS') return const Right([]);
      final statusFailure = _statusFailure(status, json);
      if (statusFailure != null) return Left(statusFailure);

      final results = (json['results'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final areas = <ServingArea>[];
      for (final result in results) {
        final area = _toServingArea(result);
        if (area != null) areas.add(area);
      }
      return Right(areas);
    } on DioException catch (error) {
      return Left(_dioFailure(error));
    } on Object catch (error) {
      return Left(
        PlacesUnknownFailure(message: 'Area lookup failed: $error'),
      );
    }
  }

  /// Maps a single geocoding result to a [ServingArea], enforcing the country
  /// guard and requiring a usable name + place id.
  ServingArea? _toServingArea(Map<String, dynamic> result) {
    final placeId = result['place_id'] as String?;
    if (placeId == null || placeId.isEmpty) return null;

    final components = (result['address_components'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    if (!_isInCountry(components)) return null;

    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    if (location == null) return null;
    final latLng = LatLng(
      (location['lat'] as num).toDouble(),
      (location['lng'] as num).toDouble(),
    );

    final name = _areaName(result, components);
    if (name.isEmpty) return null;

    return ServingArea(
      placeId: placeId,
      name: name,
      address: result['formatted_address'] as String? ?? '',
      latLng: latLng,
    );
  }

  bool _isInCountry(List<Map<String, dynamic>> components) {
    final target = _countryCode.toUpperCase();
    for (final component in components) {
      final types = (component['types'] as List<dynamic>? ?? []).cast<String>();
      if (types.contains('country')) {
        final short = (component['short_name'] as String? ?? '').toUpperCase();
        return short == target;
      }
    }
    return false;
  }

  String _areaName(
    Map<String, dynamic> result,
    List<Map<String, dynamic>> components,
  ) {
    const areaTypes = {'neighborhood', 'sublocality', 'sublocality_level_1'};
    for (final component in components) {
      final types = (component['types'] as List<dynamic>? ?? []).cast<String>();
      if (types.any(areaTypes.contains)) {
        final name = component['long_name'] as String? ?? '';
        if (name.isNotEmpty) return name;
      }
    }
    if (components.isNotEmpty) {
      return components.first['long_name'] as String? ?? '';
    }
    return result['formatted_address'] as String? ?? '';
  }

  /// Normalizes a locale identifier (`ar`, `ar_AE`, `en-US`) to the language
  /// subtag Google's `language` param expects. Returns null when empty.
  String? _language(String? localeIdentifier) {
    if (localeIdentifier == null || localeIdentifier.isEmpty) return null;
    final subtag = localeIdentifier.split(RegExp('[_-]')).first;
    return subtag.isEmpty ? null : subtag;
  }

  Failure? _statusFailure(String status, Map<String, dynamic> json) {
    if (status == 'OK') return null;
    final message = json['error_message'] as String? ?? 'Geocoding: $status';
    return switch (status) {
      'REQUEST_DENIED' => PlacesApiKeyFailure(message: message),
      'OVER_QUERY_LIMIT' => PlacesQuotaExceededFailure(message: message),
      'INVALID_REQUEST' => PlacesInvalidRequestFailure(message: message),
      _ => PlacesUnknownFailure(message: message),
    };
  }

  Failure _dioFailure(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const PlacesTimeoutFailure();
    }
    return PlacesNetworkFailure(
      message: error.message ?? 'Area lookup network request failed',
    );
  }
}

/// Fallback used when Places/Google is disabled (no API key). Returns no auto
/// areas so the coverage flow still works — the user can add areas manually.
class NoopNearbyAreasRepository implements NearbyAreasRepository {
  const NoopNearbyAreasRepository();

  @override
  TaskEither<Failure, List<ServingArea>> resolveNearbyAreas({
    required LatLng center,
    required double radiusKm,
    String? languageCode,
  }) => TaskEither.right(const []);
}
