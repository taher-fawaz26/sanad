import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/models/polygon_style.dart';
import 'package:maps/src/presentation/models/polyline_style.dart';

class MapOverlayController extends ChangeNotifier {
  final _markers = <MarkerId, Marker>{};
  final _polygons = <PolygonId, Polygon>{};
  final _polylines = <PolylineId, Polyline>{};

  Set<Marker> get markers => _markers.values.toSet();
  Set<Polygon> get polygons => _polygons.values.toSet();
  Set<Polyline> get polylines => _polylines.values.toSet();

  // ── Markers ──────────────────────────────────────────────────────────────

  void addMarker(Marker marker) {
    _markers[marker.markerId] = marker;
    notifyListeners();
  }

  void removeMarker(MarkerId id) {
    if (_markers.remove(id) != null) notifyListeners();
  }

  void setMarkers(Set<Marker> markers) {
    _markers
      ..clear()
      ..addEntries(markers.map((m) => MapEntry(m.markerId, m)));
    notifyListeners();
  }

  void clearMarkers() {
    if (_markers.isNotEmpty) {
      _markers.clear();
      notifyListeners();
    }
  }

  Marker? markerById(MarkerId id) => _markers[id];

  // ── Polygons ─────────────────────────────────────────────────────────────

  void addPolygon(Polygon polygon) {
    _polygons[polygon.polygonId] = polygon;
    notifyListeners();
  }

  void removePolygon(PolygonId id) {
    if (_polygons.remove(id) != null) notifyListeners();
  }

  void setPolygons(Set<Polygon> polygons) {
    _polygons
      ..clear()
      ..addEntries(polygons.map((p) => MapEntry(p.polygonId, p)));
    notifyListeners();
  }

  void clearPolygons() {
    if (_polygons.isNotEmpty) {
      _polygons.clear();
      notifyListeners();
    }
  }

  Polygon buildPolygon({
    required PolygonId id,
    required List<LatLng> points,
    PolygonStyle style = const PolygonStyle(),
    VoidCallback? onTap,
  }) {
    final polygon = Polygon(
      polygonId: id,
      points: points,
      strokeWidth: style.strokeWidth,
      strokeColor: style.strokeColor,
      fillColor: style.fillColor,
      geodesic: style.geodesic,
      consumeTapEvents: onTap != null,
      onTap: onTap,
    );
    _polygons[id] = polygon;
    notifyListeners();
    return polygon;
  }

  // ── Polylines ────────────────────────────────────────────────────────────

  void addPolyline(Polyline polyline) {
    _polylines[polyline.polylineId] = polyline;
    notifyListeners();
  }

  void removePolyline(PolylineId id) {
    if (_polylines.remove(id) != null) notifyListeners();
  }

  void setPolylines(Set<Polyline> polylines) {
    _polylines
      ..clear()
      ..addEntries(polylines.map((p) => MapEntry(p.polylineId, p)));
    notifyListeners();
  }

  void clearPolylines() {
    if (_polylines.isNotEmpty) {
      _polylines.clear();
      notifyListeners();
    }
  }

  Polyline buildPolyline({
    required PolylineId id,
    required List<LatLng> points,
    PolylineStyle style = const PolylineStyle(),
    VoidCallback? onTap,
  }) {
    final polyline = Polyline(
      polylineId: id,
      points: points,
      width: style.width,
      color: style.color,
      geodesic: style.geodesic,
      patterns: style.patterns,
      consumeTapEvents: onTap != null,
      onTap: onTap,
    );
    _polylines[id] = polyline;
    notifyListeners();
    return polyline;
  }

  // ── Bulk ─────────────────────────────────────────────────────────────────

  void clearAll() {
    final hadContent = _markers.isNotEmpty ||
        _polygons.isNotEmpty ||
        _polylines.isNotEmpty;
    _markers.clear();
    _polygons.clear();
    _polylines.clear();
    if (hadContent) notifyListeners();
  }
}
