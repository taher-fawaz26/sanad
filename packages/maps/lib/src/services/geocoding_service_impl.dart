import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/services/geocoding_service.dart';
import 'package:maps/src/services/location_failure_codes.dart';

class _GeocodingException implements Exception {
  const _GeocodingException({required this.message});

  final String message;

  @override
  String toString() => message;
}

/// Default implementation using the platform [geocoding] plugin.
class GeocodingServiceImpl implements GeocodingService {
  const GeocodingServiceImpl();

  @override
  TaskEither<Failure, String> addressFromCoordinates(LatLng position) {
    return TaskEither.tryCatch(
      () async {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isEmpty) {
          throw const _GeocodingException(
            message: 'No address found for the selected location.',
          );
        }
        return _formatPlacemark(placemarks.first);
      },
      (error, _) => LocationFailure(
        message: error.toString(),
        code: LocationFailureCodes.geocodingFailed,
      ),
    );
  }

  @override
  TaskEither<Failure, LatLng> coordinatesFromAddress(String address) {
    return TaskEither.tryCatch(
      () async {
        final trimmed = address.trim();
        if (trimmed.isEmpty) {
          throw const _GeocodingException(
            message: 'Search query cannot be empty.',
          );
        }

        final locations = await locationFromAddress(trimmed);
        if (locations.isEmpty) {
          throw const _GeocodingException(
            message: 'No location found for the search query.',
          );
        }

        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
      },
      (error, _) => LocationFailure(
        message: error.toString(),
        code: LocationFailureCodes.geocodingFailed,
      ),
    );
  }

  String _formatPlacemark(Placemark placemark) {
    final parts = <String>[
      if (placemark.name != null && placemark.name!.isNotEmpty) placemark.name!,
      if (placemark.street != null && placemark.street!.isNotEmpty)
        placemark.street!,
      if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty)
        placemark.subLocality!,
      if (placemark.locality != null && placemark.locality!.isNotEmpty)
        placemark.locality!,
      if (placemark.administrativeArea != null &&
          placemark.administrativeArea!.isNotEmpty)
        placemark.administrativeArea!,
      if (placemark.country != null && placemark.country!.isNotEmpty)
        placemark.country!,
    ];

    final uniqueParts = <String>[];
    for (final part in parts) {
      if (!uniqueParts.contains(part)) {
        uniqueParts.add(part);
      }
    }

    return uniqueParts.join(', ');
  }
}
