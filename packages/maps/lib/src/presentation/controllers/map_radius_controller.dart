import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/models/radius_overlay_style.dart';
import 'package:maps/src/presentation/utils/geo_math.dart';

class MapRadiusController extends ChangeNotifier {
  MapRadiusController({
    LatLng? center,
    double radiusKm = 5.0,
  }) : _center = center,
       _radiusKm = radiusKm;

  static const _metersPerKm = 1000.0;

  LatLng? _center;
  double _radiusKm;

  LatLng? get center => _center;
  double get radiusKm => _radiusKm;

  set center(LatLng? value) {
    if (_center == value) return;
    _center = value;
    notifyListeners();
  }

  set radiusKm(double value) {
    if (_radiusKm == value) return;
    _radiusKm = value;
    notifyListeners();
  }

  void update({LatLng? center, double? radiusKm}) {
    var changed = false;
    if (center != null && center != _center) {
      _center = center;
      changed = true;
    }
    if (radiusKm != null && radiusKm != _radiusKm) {
      _radiusKm = radiusKm;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Set<Circle> buildCircles({
    required Color strokeColor,
    RadiusOverlayStyle style = const RadiusOverlayStyle(),
  }) {
    final c = _center;
    if (c == null) return const {};
    return {
      Circle(
        circleId: CircleId(style.circleId),
        center: c,
        radius: _radiusKm * _metersPerKm,
        strokeColor: strokeColor,
        strokeWidth: style.strokeWidth,
        fillColor: style.fillAlpha > 0
            ? strokeColor.withValues(alpha: style.fillAlpha)
            : const Color(0x00000000),
      ),
    };
  }

  LatLngBounds? get bounds {
    final c = _center;
    if (c == null) return null;
    final region = GeoMath.boundsForRadius(c, _radiusKm);
    return LatLngBounds(
      southwest: region.southwest,
      northeast: region.northeast,
    );
  }
}
