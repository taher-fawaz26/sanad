import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:maps/src/presentation/controllers/map_camera_controller.dart';

class MapZoomControls extends StatelessWidget {
  const MapZoomControls({
    required this.cameraController,
    this.minZoom = 3,
    this.maxZoom = 20,
    super.key,
  });

  final MapCameraController cameraController;
  final double minZoom;
  final double maxZoom;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ValueListenableBuilder<double>(
      valueListenable: cameraController.zoom,
      builder: (context, zoom, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(
              responsiveDimension(8),
            ),
            boxShadow: AppShadows.small,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconButton(
                icon: Icons.add,
                size: AppIconButtonSize.large,
                onTap: zoom < maxZoom ? cameraController.zoomIn : null,
                semanticLabel: 'Zoom in',
              ),
              SizedBox(
                width: responsiveDimension(32),
                child: Divider(
                  height: 1,
                  color: colors.divider,
                ),
              ),
              AppIconButton(
                icon: Icons.remove,
                size: AppIconButtonSize.large,
                onTap: zoom > minZoom ? cameraController.zoomOut : null,
                semanticLabel: 'Zoom out',
              ),
            ],
          ),
        );
      },
    );
  }
}
