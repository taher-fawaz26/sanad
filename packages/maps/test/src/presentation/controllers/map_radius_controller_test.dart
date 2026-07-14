import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/controllers/map_radius_controller.dart';
import 'package:maps/src/presentation/models/radius_overlay_style.dart';

void main() {
  late MapRadiusController controller;

  setUp(() => controller = MapRadiusController());

  tearDown(() => controller.dispose());

  group('MapRadiusController', () {
    test('initial values', () {
      expect(controller.center, isNull);
      expect(controller.radiusKm, 5.0);
    });

    test('setting center notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.center = const LatLng(25.0, 55.0);
      expect(notified, isTrue);
      expect(controller.center, const LatLng(25.0, 55.0));
    });

    test('setting same center does not notify', () {
      controller.center = const LatLng(25.0, 55.0);
      var notified = false;
      controller.addListener(() => notified = true);
      controller.center = const LatLng(25.0, 55.0);
      expect(notified, isFalse);
    });

    test('setting radiusKm notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.radiusKm = 10;
      expect(notified, isTrue);
      expect(controller.radiusKm, 10.0);
    });

    test('update batches changes into single notification', () {
      var count = 0;
      controller.addListener(() => count++);
      controller.update(
        center: const LatLng(25.0, 55.0),
        radiusKm: 10,
      );
      expect(count, 1);
    });

    test('buildCircles returns empty set when center is null', () {
      final circles = controller.buildCircles(
        strokeColor: Colors.blue,
      );
      expect(circles, isEmpty);
    });

    test('buildCircles returns circle with correct radius', () {
      controller.update(
        center: const LatLng(25.0, 55.0),
        radiusKm: 5,
      );
      final circles = controller.buildCircles(
        strokeColor: Colors.blue,
      );
      expect(circles, hasLength(1));
      expect(circles.first.radius, 5000.0);
      expect(circles.first.center, const LatLng(25.0, 55.0));
    });

    test('buildCircles uses custom style', () {
      controller.center = const LatLng(25.0, 55.0);
      final circles = controller.buildCircles(
        strokeColor: Colors.red,
        style: const RadiusOverlayStyle(
          circleId: 'custom',
          strokeWidth: 8,
        ),
      );
      expect(circles.first.circleId, const CircleId('custom'));
      expect(circles.first.strokeWidth, 8);
    });

    test('bounds returns null when center is null', () {
      expect(controller.bounds, isNull);
    });

    test('bounds returns valid bounds when center is set', () {
      controller.update(
        center: const LatLng(25.0, 55.0),
        radiusKm: 10,
      );
      final bounds = controller.bounds!;
      expect(
        bounds.southwest.latitude,
        lessThan(bounds.northeast.latitude),
      );
    });
  });
}
