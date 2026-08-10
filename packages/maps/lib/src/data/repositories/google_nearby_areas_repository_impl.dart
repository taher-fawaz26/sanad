import 'package:app_logger/app_logger.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/domain/failures/places_failure.dart';
import 'package:maps/src/domain/repositories/nearby_areas_repository.dart';
import 'package:maps/src/presentation/utils/geo_math.dart';
import 'package:maps/src/presentation/utils/locale_subtag.dart';

/// Derives serving areas within a coverage radius directly from Google.
///
/// There is no Google API that lists neighborhoods inside a radius (Nearby
/// Search and Text Search only return businesses/POIs — political/area
/// types like `neighborhood`/`sublocality` are response-only "Table B"
/// types and cannot be used as search filters). So this reverse-geocodes a
/// bounded grid of sample points covering the circle and collects the
/// distinct neighborhoods, each with its real Google `place_id`.
///
/// Coverage is a bounded approximation, not a guaranteed-exhaustive
/// enumeration — no Google API offers that for geographic areas.
class GoogleNearbyAreasRepositoryImpl implements NearbyAreasRepository {
  GoogleNearbyAreasRepositoryImpl({
    required String apiKey,
    required Dio dio,
    String countryCode = 'ae',
    double gridSpacingKm = 1.5,
    int maxSamples = 40,
    int concurrency = 8,
  }) : _apiKey = apiKey,
       _dio = dio,
       _countryCode = countryCode,
       _gridSpacingKm = gridSpacingKm,
       _maxSamples = maxSamples,
       _concurrency = concurrency;

  final String _apiKey;
  final Dio _dio;

  /// ISO 3166-1 alpha-2 country that returned areas must belong to. Areas
  /// outside it are dropped so the user can never cover a place abroad.
  final String _countryCode;

  final double _gridSpacingKm;
  final int _maxSamples;
  final int _concurrency;

  /// Deterministic coarsening factor applied to spacing when the generated
  /// grid exceeds [_maxSamples], reapplied until the sample count fits.
  static const _coarsenFactor = 1.5;

  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  /// Neighborhood granularity — the "areas" the product means. Deliberately
  /// excludes `locality` (too coarse; would surface whole cities) and any
  /// business/POI or route/administrative types.
  static const _resultType = 'neighborhood|sublocality|sublocality_level_1';

  static const _areaTypePriority = [
    'neighborhood',
    'sublocality_level_1',
    'sublocality',
  ];

  /// Session-lifetime cache of reverse-geocode results keyed by quantized
  /// sample coordinate + language, so re-resolves (e.g. minor radius nudges)
  /// don't re-fetch samples already seen this session.
  final Map<String, List<ServingArea>> _sampleCache = {};

  @override
  TaskEither<Failure, NearbyAreasResult> resolveNearbyAreas({
    required LatLng center,
    required double radiusKm,
    String? languageCode,
  }) {
    return TaskEither(() async {
      final samples = _boundedSamplePoints(center: center, radiusKm: radiusKm);
      final language = localeSubtag(languageCode);

      final areasByPlaceId = <String, ServingArea>{};
      Failure? firstFailure;
      var anySuccess = false;
      var anyFailure = false;

      for (var i = 0; i < samples.length; i += _concurrency) {
        final chunk = samples.sublist(
          i,
          (i + _concurrency).clamp(0, samples.length),
        );
        final outcomes = await Future.wait(
          chunk.map(
            (point) => _reverseGeocodeCached(point, language: language),
          ),
        );

        for (final outcome in outcomes) {
          outcome.match(
            (failure) {
              anyFailure = true;
              firstFailure ??= failure;
            },
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
      }

      // Only fail the whole resolve when every sample errored. A partial set
      // of successes is still useful, and a single flaky sample must not
      // blank the coverage list — the caller is told via hadPartialFailure.
      if (!anySuccess && firstFailure != null) {
        return Either.left(firstFailure!);
      }

      return Either.right(
        NearbyAreasResult(
          areas: areasByPlaceId.values.toList(growable: false),
          hadPartialFailure: anySuccess && anyFailure,
        ),
      );
    });
  }

  /// Generates the sample grid, deterministically coarsening spacing until
  /// the sample count fits [_maxSamples]. Logs when coverage is bounded so
  /// this is never a silent truncation.
  List<LatLng> _boundedSamplePoints({
    required LatLng center,
    required double radiusKm,
  }) {
    var spacing = _gridSpacingKm;
    var points = GeoMath.gridSamplePoints(
      center,
      radiusKm: radiusKm,
      spacingKm: spacing,
    );

    while (points.length > _maxSamples) {
      spacing *= _coarsenFactor;
      points = GeoMath.gridSamplePoints(
        center,
        radiusKm: radiusKm,
        spacingKm: spacing,
      );
    }

    if (spacing != _gridSpacingKm) {
      appLogger.w(
        'Serving-area discovery: coverage bounded — spacing coarsened '
        'from ${_gridSpacingKm}km to ${spacing.toStringAsFixed(2)}km '
        '(${points.length} samples, cap $_maxSamples) '
        'for radius ${radiusKm}km.',
      );
    }

    return points;
  }

  Future<Either<Failure, List<ServingArea>>> _reverseGeocodeCached(
    LatLng point, {
    String? language,
  }) async {
    final key = _cacheKey(point, language);
    final cached = _sampleCache[key];
    if (cached != null) return Right(cached);

    final result = await _reverseGeocode(point, language: language);
    return result.map((areas) {
      _sampleCache[key] = areas;
      return areas;
    });
  }

  String _cacheKey(LatLng point, String? language) {
    final lat = point.latitude.toStringAsFixed(4);
    final lng = point.longitude.toStringAsFixed(4);
    return '$lat,$lng|${language ?? ''}';
  }

  Future<Either<Failure, List<ServingArea>>> _reverseGeocode(
    LatLng point, {
    String? language,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _geocodeUrl,
        queryParameters: <String, String>{
          'latlng': '${point.latitude},${point.longitude}',
          'key': _apiKey,
          'result_type': _resultType,
          'region': _countryCode,
          if (language != null) 'language': language,
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
  /// guard and requiring a usable name + RAW Google `place_id`.
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
    for (final areaType in _areaTypePriority) {
      for (final component in components) {
        final types = (component['types'] as List<dynamic>? ?? [])
            .cast<String>();
        if (types.contains(areaType)) {
          final name = component['long_name'] as String? ?? '';
          if (name.isNotEmpty) return name;
        }
      }
    }
    if (components.isNotEmpty) {
      return components.first['long_name'] as String? ?? '';
    }
    return result['formatted_address'] as String? ?? '';
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
  TaskEither<Failure, NearbyAreasResult> resolveNearbyAreas({
    required LatLng center,
    required double radiusKm,
    String? languageCode,
  }) => TaskEither.right(const NearbyAreasResult(areas: []));
}
