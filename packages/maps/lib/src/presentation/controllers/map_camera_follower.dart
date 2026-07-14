import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/controllers/map_camera_controller.dart';

class MapCameraFollower {
  MapCameraFollower(this._cameraController, {this.zoom});

  final MapCameraController _cameraController;
  final double? zoom;

  StreamSubscription<LatLng>? _subscription;
  final _isFollowing = ValueNotifier<bool>(false);

  ValueListenable<bool> get isFollowing => _isFollowing;

  void follow(Stream<LatLng> positionStream) {
    stop();
    _isFollowing.value = true;
    _subscription = positionStream.listen(
      (position) {
        if (!_isFollowing.value) return;
        unawaited(
          _cameraController.animateTo(position, zoom: zoom),
        );
      },
      onDone: () => _isFollowing.value = false,
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _isFollowing.value = false;
  }

  void dispose() {
    stop();
    _isFollowing.dispose();
  }
}
