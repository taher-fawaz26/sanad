import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/data/models/place_prediction_dto.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/domain/failures/places_failure.dart';
import 'package:maps/src/services/places_provider.dart';

class GooglePlacesProvider implements PlacesProvider {
  GooglePlacesProvider({required String apiKey, required Dio dio})
    : _apiKey = apiKey,
      _dio = dio;

  final String _apiKey;
  final Dio _dio;

  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  @override
  TaskEither<Failure, List<PlacePrediction>> autocomplete({
    required String query,
    String? sessionToken,
    String? language,
    LatLng? location,
    int? radiusMeters,
  }) {
    return TaskEither.tryCatch(
      () async {
        final params = <String, String>{
          'input': query,
          'key': _apiKey,
          if (sessionToken != null) 'sessiontoken': sessionToken,
          if (language != null) 'language': language,
          if (location != null)
            'location': '${location.latitude},${location.longitude}',
          if (radiusMeters != null) 'radius': radiusMeters.toString(),
        };

        final response = await _dio.get<Map<String, dynamic>>(
          _autocompleteUrl,
          queryParameters: params,
        );
        final json = response.data!;

        final status = json['status'] as String;
        if (status == 'ZERO_RESULTS') return <PlacePrediction>[];
        _throwOnStatus(status, json);

        return (json['predictions'] as List<dynamic>)
            .map(
              (e) => PlacePredictionDto.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      },
      _mapError,
    );
  }

  @override
  TaskEither<Failure, LatLng> getPlaceDetails({
    required String placeId,
    String? sessionToken,
  }) {
    return TaskEither.tryCatch(
      () async {
        final params = <String, String>{
          'place_id': placeId,
          'key': _apiKey,
          'fields': 'geometry',
          if (sessionToken != null) 'sessiontoken': sessionToken,
        };

        final response = await _dio.get<Map<String, dynamic>>(
          _detailsUrl,
          queryParameters: params,
        );
        final json = response.data!;

        final status = json['status'] as String;
        _throwOnStatus(status, json);

        final result = json['result'] as Map<String, dynamic>;
        final geometry = result['geometry'] as Map<String, dynamic>;
        final loc = geometry['location'] as Map<String, dynamic>;
        return LatLng(
          (loc['lat'] as num).toDouble(),
          (loc['lng'] as num).toDouble(),
        );
      },
      _mapError,
    );
  }

  static void _throwOnStatus(String status, Map<String, dynamic> json) {
    if (status == 'OK') return;
    final errorMsg = json['error_message'] as String? ?? 'Places API: $status';
    throw switch (status) {
      'REQUEST_DENIED' => _PlacesApiKeyException(errorMsg),
      'OVER_QUERY_LIMIT' => _PlacesQuotaException(errorMsg),
      'INVALID_REQUEST' => _PlacesInvalidRequestException(errorMsg),
      _ => _PlacesStatusException(errorMsg),
    };
  }

  static Failure _mapError(Object error, StackTrace _) {
    if (error is _PlacesApiKeyException) {
      return PlacesApiKeyFailure(message: error.message);
    }
    if (error is _PlacesQuotaException) {
      return PlacesQuotaExceededFailure(message: error.message);
    }
    if (error is _PlacesInvalidRequestException) {
      return PlacesInvalidRequestFailure(message: error.message);
    }
    if (error is _PlacesStatusException) {
      return PlacesUnknownFailure(message: error.message);
    }
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return const PlacesTimeoutFailure();
      }
      return PlacesNetworkFailure(
        message: error.message ?? 'Places network request failed',
      );
    }
    return PlacesUnknownFailure(
      message: 'Places request failed: $error',
    );
  }
}

class _PlacesApiKeyException implements Exception {
  const _PlacesApiKeyException(this.message);
  final String message;
}

class _PlacesQuotaException implements Exception {
  const _PlacesQuotaException(this.message);
  final String message;
}

class _PlacesInvalidRequestException implements Exception {
  const _PlacesInvalidRequestException(this.message);
  final String message;
}

class _PlacesStatusException implements Exception {
  const _PlacesStatusException(this.message);
  final String message;
}
