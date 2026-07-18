import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/data/cache/geocoding_cache.dart';
import 'package:maps/src/domain/entities/geocoded_address.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/domain/repositories/geocoding_repository.dart';
import 'package:maps/src/services/geocoding_service.dart';

/// [GeocodingRepository] backed by [GeocodingService] with an LRU cache
/// for reverse-geocode results.
class GeocodingRepositoryImpl implements GeocodingRepository {
  GeocodingRepositoryImpl(
    this._service, {
    GeocodingCache? cache,
  }) : _cache = cache ?? GeocodingCache();

  final GeocodingService _service;
  final GeocodingCache _cache;

  @override
  TaskEither<Failure, GeocodedAddress> reverseGeocode(
    LatLng position, {
    String? localeIdentifier,
  }) {
    final cacheKey = _cache.keyFor(position, localeIdentifier);
    final cached = _cache.get(cacheKey);
    if (cached != null) return TaskEither.right(cached);

    return _service
        .addressFromCoordinates(
          position,
          localeIdentifier: localeIdentifier,
        )
        .map((geocoded) {
          _cache.put(cacheKey, geocoded);
          return geocoded;
        });
  }

  @override
  TaskEither<Failure, LatLng> forwardGeocode(
    String address, {
    String? localeIdentifier,
  }) {
    return _service.coordinatesFromAddress(
      address,
      localeIdentifier: localeIdentifier,
    );
  }

  @override
  TaskEither<Failure, List<ServingArea>> nearbyAreaNames({
    required LatLng center,
    required double radiusKm,
    String? localeIdentifier,
  }) {
    return _service.nearbyAreaNames(
      center: center,
      radiusKm: radiusKm,
      localeIdentifier: localeIdentifier,
    );
  }
}
