import 'package:app_logger/app_logger.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/geocoded_address.dart';
import 'package:maps/src/domain/failures/places_failure.dart';
import 'package:maps/src/domain/repositories/reverse_geocode_place_repository.dart';
import 'package:maps/src/presentation/utils/locale_subtag.dart';

/// Google REST Geocoding-API implementation of [ReverseGeocodePlaceRepository].
///
/// Mirrors the request shape already used by `GoogleNearbyAreasRepositoryImpl`
/// (same endpoint, key, region) but takes the single best street-level result
/// for the exact coordinate — the one that carries the `place_id` the backend
/// needs for a branch location. Never restricts `result_type`, so it resolves
/// the precise picked point rather than only political areas.
class GoogleReverseGeocodePlaceRepositoryImpl
    implements ReverseGeocodePlaceRepository {
  GoogleReverseGeocodePlaceRepositoryImpl({
    required String apiKey,
    required Dio dio,
    String countryCode = 'ae',
  }) : _apiKey = apiKey,
       _dio = dio,
       _countryCode = countryCode;

  final String _apiKey;
  final Dio _dio;
  final String _countryCode;

  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  @override
  TaskEither<Failure, GeocodedAddress?> reverseGeocodePlace({
    required LatLng position,
    String? languageCode,
  }) {
    return TaskEither.tryCatch(
      () async {
        final language = localeSubtag(languageCode);
        final response = await _dio.get<Map<String, dynamic>>(
          _geocodeUrl,
          queryParameters: <String, String>{
            'latlng': '${position.latitude},${position.longitude}',
            'key': _apiKey,
            'region': _countryCode,
            if (language != null) 'language': language,
          },
        );
        final json = response.data!;
        final status = json['status'] as String;
        // Never log the API key — only HTTP + Google's own status field.
        appLogger.d(
          '[ReverseGeocodePlace] httpStatus=${response.statusCode} '
          'googleStatus=$status',
        );
        if (status == 'ZERO_RESULTS') return null;
        _throwOnStatus(status, json);

        final results = (json['results'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final result in results) {
          final address = _toAddress(result);
          if (address != null) return address;
        }
        return null;
      },
      _mapError,
    );
  }

  /// Maps a geocoding result to a [GeocodedAddress], requiring a usable
  /// `place_id` + `formatted_address`. Returns null when either is missing so
  /// the caller can fall through to the next (coarser) result.
  GeocodedAddress? _toAddress(Map<String, dynamic> result) {
    final placeId = result['place_id'] as String?;
    if (placeId == null || placeId.isEmpty) return null;
    final formatted = result['formatted_address'] as String?;
    if (formatted == null || formatted.isEmpty) return null;

    return GeocodedAddress(
      formattedAddress: formatted,
      isoCountryCode: _countryFromComponents(result),
      placeId: placeId,
    );
  }

  String? _countryFromComponents(Map<String, dynamic> result) {
    final components = (result['address_components'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    for (final component in components) {
      final types = (component['types'] as List<dynamic>? ?? []).cast<String>();
      if (types.contains('country')) {
        final short = component['short_name'] as String?;
        if (short != null && short.isNotEmpty) return short.toUpperCase();
      }
    }
    return null;
  }

  void _throwOnStatus(String status, Map<String, dynamic> json) {
    if (status == 'OK') return;
    final message = json['error_message'] as String? ?? 'Geocoding: $status';
    throw _GeocodeStatusException(
      switch (status) {
        'REQUEST_DENIED' => PlacesApiKeyFailure(message: message),
        'OVER_QUERY_LIMIT' => PlacesQuotaExceededFailure(message: message),
        'INVALID_REQUEST' => PlacesInvalidRequestFailure(message: message),
        _ => PlacesUnknownFailure(message: message),
      },
    );
  }

  static Failure _mapError(Object error, StackTrace _) {
    if (error is _GeocodeStatusException) return error.failure;
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return const PlacesTimeoutFailure();
      }
      return PlacesNetworkFailure(
        message: error.message ?? 'Reverse-geocode network request failed',
      );
    }
    return PlacesUnknownFailure(message: 'Reverse-geocode failed: $error');
  }
}

/// Wraps a mapped [Failure] thrown out of the async body so `tryCatch`'s error
/// handler can surface it (throwing a raw [Failure] trips `only_throw_errors`).
class _GeocodeStatusException implements Exception {
  const _GeocodeStatusException(this.failure);

  final Failure failure;
}
