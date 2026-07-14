import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/controllers/map_overlay_controller.dart';
import 'package:maps/src/presentation/models/polygon_style.dart';
import 'package:maps/src/presentation/models/polyline_style.dart';

void main() {
  late MapOverlayController controller;

  setUp(() => controller = MapOverlayController());

  tearDown(() => controller.dispose());

  group('MapOverlayController — Markers', () {
    test('starts with empty markers', () {
      expect(controller.markers, isEmpty);
    });

    test('addMarker adds and notifies', () {
      var notified = false;
      controller.addListener(() => notified = true);

      const marker = Marker(markerId: MarkerId('m1'));
      controller.addMarker(marker);

      expect(notified, isTrue);
      expect(controller.markers, hasLength(1));
    });

    test('removeMarker removes by id', () {
      const marker = Marker(markerId: MarkerId('m1'));
      controller.addMarker(marker);
      controller.removeMarker(const MarkerId('m1'));
      expect(controller.markers, isEmpty);
    });

    test('removeMarker does not notify for missing id', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.removeMarker(const MarkerId('missing'));
      expect(notified, isFalse);
    });

    test('setMarkers replaces all', () {
      controller.addMarker(const Marker(markerId: MarkerId('m1')));
      controller.setMarkers({
        const Marker(markerId: MarkerId('m2')),
        const Marker(markerId: MarkerId('m3')),
      });
      expect(controller.markers, hasLength(2));
      expect(
        controller.markerById(const MarkerId('m1')),
        isNull,
      );
    });

    test('clearMarkers empties and notifies', () {
      controller.addMarker(const Marker(markerId: MarkerId('m1')));
      var notified = false;
      controller.addListener(() => notified = true);
      controller.clearMarkers();
      expect(notified, isTrue);
      expect(controller.markers, isEmpty);
    });

    test('clearMarkers on empty does not notify', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.clearMarkers();
      expect(notified, isFalse);
    });
  });

  group('MapOverlayController — Polygons', () {
    test('buildPolygon adds and returns polygon', () {
      final polygon = controller.buildPolygon(
        id: const PolygonId('p1'),
        points: const [
          LatLng(25.0, 55.0),
          LatLng(25.1, 55.0),
          LatLng(25.1, 55.1),
        ],
        style: const PolygonStyle(strokeWidth: 3),
      );
      expect(polygon.polygonId, const PolygonId('p1'));
      expect(controller.polygons, hasLength(1));
    });

    test('removePolygon removes by id', () {
      controller.buildPolygon(
        id: const PolygonId('p1'),
        points: const [LatLng(25.0, 55.0)],
      );
      controller.removePolygon(const PolygonId('p1'));
      expect(controller.polygons, isEmpty);
    });
  });

  group('MapOverlayController — Polylines', () {
    test('buildPolyline adds and returns polyline', () {
      final polyline = controller.buildPolyline(
        id: const PolylineId('pl1'),
        points: const [
          LatLng(25.0, 55.0),
          LatLng(25.1, 55.1),
        ],
        style: const PolylineStyle(width: 6, color: Colors.red),
      );
      expect(polyline.polylineId, const PolylineId('pl1'));
      expect(controller.polylines, hasLength(1));
    });
  });

  group('MapOverlayController — clearAll', () {
    test('clears everything and notifies once', () {
      controller
        ..addMarker(const Marker(markerId: MarkerId('m1')))
        ..buildPolygon(
          id: const PolygonId('p1'),
          points: const [LatLng(25.0, 55.0)],
        )
        ..buildPolyline(
          id: const PolylineId('pl1'),
          points: const [LatLng(25.0, 55.0)],
        );

      var count = 0;
      controller.addListener(() => count++);
      controller.clearAll();

      expect(count, 1);
      expect(controller.markers, isEmpty);
      expect(controller.polygons, isEmpty);
      expect(controller.polylines, isEmpty);
    });

    test('clearAll on empty does not notify', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.clearAll();
      expect(notified, isFalse);
    });
  });
}
