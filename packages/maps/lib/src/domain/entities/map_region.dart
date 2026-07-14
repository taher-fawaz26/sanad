import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A rectangular geographic region defined by its corners.
class MapRegion extends Equatable {
  const MapRegion({
    required this.southwest,
    required this.northeast,
  });

  final LatLng southwest;
  final LatLng northeast;

  LatLng get center => LatLng(
        (southwest.latitude + northeast.latitude) / 2,
        (southwest.longitude + northeast.longitude) / 2,
      );

  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
        point.latitude <= northeast.latitude &&
        point.longitude >= southwest.longitude &&
        point.longitude <= northeast.longitude;
  }

  @override
  List<Object?> get props => [southwest, northeast];
}
