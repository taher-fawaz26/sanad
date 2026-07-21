import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/camera/default_map_viewport.dart';
import 'package:maps/src/presentation/camera/initial_camera_resolver.dart';

void main() {
  const existing = LatLng(24.4539, 54.3773); // Abu Dhabi
  const initial = LatLng(25.2048, 55.2708); // Dubai (a different point)

  group('InitialCameraResolver.resolveInitialLocation — priority', () {
    test('existing (saved/edit) wins over explicit initial', () {
      final result = InitialCameraResolver.resolveInitialLocation(
        existingLocation: existing,
        initialLocation: initial,
      );
      expect(result, existing);
    });

    test('explicit initial used when no saved location', () {
      final result = InitialCameraResolver.resolveInitialLocation(
        initialLocation: initial,
      );
      expect(result, initial);
    });

    test('null when neither provided (→ default viewport, no pin)', () {
      expect(InitialCameraResolver.resolveInitialLocation(), isNull);
    });
  });

  group('InitialCameraResolver.resolveCamera — priority', () {
    test('1. saved location', () {
      final camera = InitialCameraResolver.resolveCamera(
        existingLocation: existing,
        initialLocation: initial,
      );
      expect(camera.target, existing);
    });

    test('2. explicit initial when no saved', () {
      final camera = InitialCameraResolver.resolveCamera(
        initialLocation: initial,
      );
      expect(camera.target, initial);
    });

    test('3. UAE default (Dubai) when neither provided', () {
      final camera = InitialCameraResolver.resolveCamera();
      expect(camera.target, DefaultMapViewport.center);
      expect(camera.zoom, DefaultMapViewport.defaultZoom);
    });

    test('never resolves to a current/GPS location (no such input exists)', () {
      // The API surface has no current-location parameter; GPS can only reach
      // the camera via an explicit user action, never via resolution.
      final camera = InitialCameraResolver.resolveCamera();
      expect(camera.target, DefaultMapViewport.center);
    });

    test('applies provided zoom to a resolved location', () {
      final camera = InitialCameraResolver.resolveCamera(
        existingLocation: existing,
        zoom: 17,
      );
      expect(camera.zoom, 17);
    });

    test('applies provided zoom to the default viewport', () {
      final camera = InitialCameraResolver.resolveCamera(zoom: 11);
      expect(camera.target, DefaultMapViewport.center);
      expect(camera.zoom, 11);
    });

    test('falls back to default zoom when omitted', () {
      final camera = InitialCameraResolver.resolveCamera(
        initialLocation: initial,
      );
      expect(camera.zoom, DefaultMapViewport.defaultZoom);
    });
  });

  group('DefaultMapViewport', () {
    test('centers on Dubai / the UAE', () {
      expect(DefaultMapViewport.center.latitude, closeTo(25.0772, 0.0001));
      expect(DefaultMapViewport.center.longitude, closeTo(55.1396, 0.0001));
    });

    test('UAE bounds contain the default center', () {
      final sw = DefaultMapViewport.uaeBounds.southwest;
      final ne = DefaultMapViewport.uaeBounds.northeast;
      final c = DefaultMapViewport.center;
      expect(c.latitude, inInclusiveRange(sw.latitude, ne.latitude));
      expect(c.longitude, inInclusiveRange(sw.longitude, ne.longitude));
    });
  });
}
