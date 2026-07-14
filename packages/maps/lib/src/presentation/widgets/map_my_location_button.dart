import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/presentation/controllers/map_camera_controller.dart';

class MapMyLocationButton extends StatefulWidget {
  const MapMyLocationButton({
    required this.cameraController,
    required this.getCurrentLocationUseCase,
    this.zoom,
    super.key,
  });

  final MapCameraController cameraController;
  final GetCurrentLocationUseCase getCurrentLocationUseCase;
  final double? zoom;

  @override
  State<MapMyLocationButton> createState() => _MapMyLocationButtonState();
}

class _MapMyLocationButtonState extends State<MapMyLocationButton> {
  bool _loading = false;

  Future<void> _goToMyLocation() async {
    if (_loading) return;
    setState(() => _loading = true);

    final result = await widget.getCurrentLocationUseCase(
      const NoParams(),
    ).run();

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (_) {},
      (position) {
        unawaited(
          widget.cameraController.animateTo(
            position,
            zoom: widget.zoom,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          responsiveDimension(8),
        ),
        boxShadow: AppShadows.small,
      ),
      child: _loading
          ? SizedBox(
              width: responsiveDimension(40),
              height: responsiveDimension(40),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : AppIconButton(
              icon: Icons.my_location,
              size: AppIconButtonSize.large,
              onTap: _goToMyLocation,
            ),
    );
  }
}
