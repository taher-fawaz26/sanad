import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/services/places_provider.dart';

class OsmPlacesProvider implements PlacesProvider {
  const OsmPlacesProvider();

  @override
  TaskEither<Failure, List<PlacePrediction>> autocomplete({
    required String query,
    String? sessionToken,
    String? language,
    LatLng? location,
    int? radiusMeters,
  }) {
    return TaskEither.left(
      const UnknownFailure(
        message: 'OsmPlacesProvider is not yet implemented',
        code: 'PLACES_NOT_IMPLEMENTED',
      ),
    );
  }

  @override
  TaskEither<Failure, LatLng> getPlaceDetails({
    required String placeId,
    String? sessionToken,
  }) {
    return TaskEither.left(
      const UnknownFailure(
        message: 'OsmPlacesProvider is not yet implemented',
        code: 'PLACES_NOT_IMPLEMENTED',
      ),
    );
  }
}
