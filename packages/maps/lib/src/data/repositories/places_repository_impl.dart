import 'dart:math';

import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/domain/repositories/places_repository.dart';
import 'package:maps/src/services/places_provider.dart';

/// [PlacesRepository] backed by [PlacesProvider] with automatic session
/// token management for billing efficiency.
class PlacesRepositoryImpl implements PlacesRepository {
  PlacesRepositoryImpl(this._provider);

  final PlacesProvider _provider;
  String? _sessionToken;

  @override
  TaskEither<Failure, List<PlacePrediction>> searchPlaces({
    required String query,
    String? language,
    LatLng? biasLocation,
    int? biasRadiusMeters,
    String? types,
  }) {
    return _provider.autocomplete(
      query: query,
      sessionToken: _ensureSessionToken(),
      language: language,
      location: biasLocation,
      radiusMeters: biasRadiusMeters,
      types: types,
    );
  }

  @override
  TaskEither<Failure, LatLng> getPlaceCoordinates({
    required String placeId,
  }) {
    final token = _sessionToken;
    _sessionToken = null;
    return _provider.getPlaceDetails(
      placeId: placeId,
      sessionToken: token,
    );
  }

  @override
  void resetSession() {
    _sessionToken = null;
  }

  String _ensureSessionToken() {
    return _sessionToken ??= _generateToken();
  }

  static String _generateToken() {
    final random = Random();
    return List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }
}
