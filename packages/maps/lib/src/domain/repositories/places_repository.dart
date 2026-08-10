import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';

abstract class PlacesRepository {
  TaskEither<Failure, List<PlacePrediction>> searchPlaces({
    required String query,
    String? language,
    LatLng? biasLocation,
    int? biasRadiusMeters,
    String? types,
  });

  TaskEither<Failure, LatLng> getPlaceCoordinates({
    required String placeId,
  });

  void resetSession();
}
