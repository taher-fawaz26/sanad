import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/controllers/map_camera_controller.dart';
import 'package:maps/src/presentation/controllers/map_camera_follower.dart';
import 'package:mocktail/mocktail.dart';

class _MockCameraController extends Mock implements MapCameraController {}

void main() {
  late _MockCameraController cameraController;
  late MapCameraFollower follower;

  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
  });

  setUp(() {
    cameraController = _MockCameraController();
    when(() => cameraController.animateTo(any(), zoom: any(named: 'zoom')))
        .thenAnswer((_) async {});
    follower = MapCameraFollower(cameraController);
  });

  tearDown(() => follower.dispose());

  group('MapCameraFollower', () {
    test('isFollowing starts false', () {
      expect(follower.isFollowing.value, isFalse);
    });

    test('follow sets isFollowing to true', () {
      final controller = StreamController<LatLng>();
      addTearDown(controller.close);

      follower.follow(controller.stream);
      expect(follower.isFollowing.value, isTrue);
    });

    test('follow animates camera on new positions', () async {
      final controller = StreamController<LatLng>();
      addTearDown(controller.close);

      follower.follow(controller.stream);
      controller.add(const LatLng(25.0, 55.0));
      await Future<void>.delayed(Duration.zero);

      verify(
        () => cameraController.animateTo(
          const LatLng(25.0, 55.0),
          zoom: any(named: 'zoom'),
        ),
      ).called(1);
    });

    test('stop cancels subscription and sets isFollowing to false', () {
      final controller = StreamController<LatLng>();
      addTearDown(controller.close);

      follower.follow(controller.stream);
      expect(follower.isFollowing.value, isTrue);

      follower.stop();
      expect(follower.isFollowing.value, isFalse);
    });

    test('stop prevents further camera updates', () async {
      final controller = StreamController<LatLng>();
      addTearDown(controller.close);

      follower.follow(controller.stream);
      follower.stop();

      controller.add(const LatLng(25.0, 55.0));
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => cameraController.animateTo(any(), zoom: any(named: 'zoom')),
      );
    });

    test('follow replaces previous subscription', () async {
      final first = StreamController<LatLng>();
      final second = StreamController<LatLng>();
      addTearDown(first.close);
      addTearDown(second.close);

      follower.follow(first.stream);
      follower.follow(second.stream);

      first.add(const LatLng(1, 1));
      second.add(const LatLng(2, 2));
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => cameraController.animateTo(
          const LatLng(1, 1),
          zoom: any(named: 'zoom'),
        ),
      );
      verify(
        () => cameraController.animateTo(
          const LatLng(2, 2),
          zoom: any(named: 'zoom'),
        ),
      ).called(1);
    });

    test('stream onDone sets isFollowing to false', () async {
      final controller = StreamController<LatLng>();

      follower.follow(controller.stream);
      expect(follower.isFollowing.value, isTrue);

      await controller.close();
      await Future<void>.delayed(Duration.zero);

      expect(follower.isFollowing.value, isFalse);
    });

    test('passes zoom parameter to camera controller', () async {
      final zoomFollower = MapCameraFollower(cameraController, zoom: 16);
      addTearDown(zoomFollower.dispose);

      final controller = StreamController<LatLng>();
      addTearDown(controller.close);

      zoomFollower.follow(controller.stream);
      controller.add(const LatLng(25.0, 55.0));
      await Future<void>.delayed(Duration.zero);

      verify(
        () => cameraController.animateTo(
          const LatLng(25.0, 55.0),
          zoom: 16,
        ),
      ).called(1);
    });
  });
}
