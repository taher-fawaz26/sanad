import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';

abstract class PlacesProvider {
  TaskEither<Failure, List<PlacePrediction>> autocomplete({
    required String query,
    String? sessionToken,
    String? language,
    LatLng? location,
    int? radiusMeters,
  });

  TaskEither<Failure, LatLng> getPlaceDetails({
    required String placeId,
    String? sessionToken,
  });
}
