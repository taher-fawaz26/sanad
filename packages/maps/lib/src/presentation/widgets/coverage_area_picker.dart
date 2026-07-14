import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/bloc/coverage_area/coverage_area_bloc.dart';
import 'package:maps/src/presentation/controllers/map_camera_controller.dart';
import 'package:maps/src/presentation/controllers/map_radius_controller.dart';
import 'package:maps/src/presentation/models/coverage_area_labels.dart';
import 'package:maps/src/presentation/models/map_configuration.dart';
import 'package:maps/src/presentation/models/radius_overlay_style.dart';
import 'package:maps/src/presentation/models/radius_preset.dart';
import 'package:maps/src/presentation/widgets/animated_circle_overlay.dart';
import 'package:maps/src/presentation/widgets/nearby_places_sheet.dart';
import 'package:maps/src/presentation/widgets/radius_selector.dart';
import 'package:maps/src/widgets/app_google_map.dart';

class CoverageAreaPicker extends StatefulWidget {
  const CoverageAreaPicker({
    required this.labels,
    this.initialPosition,
    this.initialAddress,
    this.initialRadiusKm,
    this.configuration = const MapConfiguration(),
    this.radiusPresets = const [],
    this.minRadius = 1,
    this.maxRadius = 30,
    this.radiusOverlayStyle = const RadiusOverlayStyle(),
    this.onConfirm,
    super.key,
  });

  final CoverageAreaLabels labels;
  final LatLng? initialPosition;
  final String? initialAddress;
  final double? initialRadiusKm;
  final MapConfiguration configuration;
  final List<RadiusPreset> radiusPresets;
  final double minRadius;
  final double maxRadius;
  final RadiusOverlayStyle radiusOverlayStyle;
  final void Function(CoverageAreaState state)? onConfirm;

  @override
  State<CoverageAreaPicker> createState() => _CoverageAreaPickerState();
}

class _CoverageAreaPickerState extends State<CoverageAreaPicker> {
  final _cameraController = MapCameraController();
  final _radiusController = MapRadiusController();

  @override
  void dispose() {
    _cameraController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _syncRadius(CoverageAreaState state) {
    _radiusController.update(
      center: state.position,
      radiusKm: state.radiusKm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final config = widget.configuration;
    final colors = context.appColors;

    return BlocProvider(
      create: (_) => sl<CoverageAreaBloc>()
        ..add(
          CoverageAreaStarted(
            initialPosition: widget.initialPosition,
            initialAddress: widget.initialAddress,
            initialRadiusKm: widget.initialRadiusKm,
            localeIdentifier:
                Localizations.localeOf(context).toString(),
          ),
        ),
      child: BlocConsumer<CoverageAreaBloc, CoverageAreaState>(
        listenWhen: (prev, curr) =>
            prev.position != curr.position ||
            prev.radiusKm != curr.radiusKm ||
            prev.cameraSource != curr.cameraSource,
        listener: (context, state) {
          _syncRadius(state);
          if (state.cameraSource ==
                  CoverageAreaCameraSource.programmatic &&
              state.position != null) {
            _cameraController.fitCircle(
              state.position!,
              radiusKm: state.radiusKm,
            );
          }
        },
        builder: (context, state) {
          final initialPosition =
              state.position ?? config.initialPosition;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: responsiveDimension(280),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    responsiveDimension(20),
                  ),
                  child: AnimatedCircleOverlay(
                    center: state.position,
                    radiusKm: state.radiusKm,
                    strokeColor: colors.primary,
                    style: widget.radiusOverlayStyle,
                    builder: (circles) => AppGoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initialPosition,
                        zoom: config.initialZoom,
                      ),
                      circles: circles,
                      onMapCreated: _cameraController.onMapCreated,
                      onCameraMove: _cameraController.onCameraMove,
                      tiltGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              RadiusSelector(
                radiusKm: state.radiusKm,
                label: labels.radiusLabel,
                min: widget.minRadius,
                max: widget.maxRadius,
                presets: widget.radiusPresets,
                onChanged: (radius) {
                  context.read<CoverageAreaBloc>().add(
                    CoverageAreaRadiusChanged(radius),
                  );
                },
              ),
              SizedBox(height: AppSpacing.md),
              NearbyPlacesSheet(
                title: labels.coveredAreasTitle,
                places: state.coveredAreas,
                emptyMessage: labels.noAreasMessage,
                onPlaceRemoved: (area) {
                  context.read<CoverageAreaBloc>().add(
                    CoverageAreaAreaRemoved(area),
                  );
                },
              ),
              SizedBox(height: AppSpacing.md),
              AppButton(
                label: labels.confirm,
                onPressed: state.canConfirm
                    ? () => widget.onConfirm?.call(state)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
