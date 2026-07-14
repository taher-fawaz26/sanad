import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/presentation/bloc/location_picker/location_picker_bloc.dart';
import 'package:maps/src/presentation/controllers/map_camera_controller.dart';
import 'package:maps/src/presentation/models/location_picker_labels.dart';
import 'package:maps/src/presentation/models/location_picker_result.dart';
import 'package:maps/src/presentation/models/map_configuration.dart';
import 'package:maps/src/widgets/app_google_map.dart';

Future<LocationPickerResult?> showLocationPickerSheet(
  BuildContext context, {
  required LocationPickerLabels labels,
  LatLng? initialPosition,
  String? initialAddress,
  MapConfiguration configuration = const MapConfiguration(),
  Widget? pinMarker,
}) {
  final localeIdentifier = Localizations.localeOf(context).toString();
  return showAppBottomSheet<LocationPickerResult>(
    context: context,
    showDragHandle: false,
    child: BlocProvider(
      create: (_) => sl<LocationPickerBloc>()
        ..add(
          LocationPickerStarted(
            initialPosition: initialPosition,
            initialAddress: initialAddress,
            localeIdentifier: localeIdentifier,
          ),
        ),
      child: _LocationPickerSheet(
        labels: labels,
        configuration: configuration,
        pinMarker: pinMarker,
      ),
    ),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({
    required this.labels,
    required this.configuration,
    this.pinMarker,
  });

  final LocationPickerLabels labels;
  final MapConfiguration configuration;
  final Widget? pinMarker;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _searchController = TextEditingController();
  final _cameraController = MapCameraController();
  final _debouncer = Debouncer();

  @override
  void dispose() {
    _searchController.dispose();
    _cameraController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onCameraIdle() {
    if (_cameraController.isAnimating.value) return;
    final target = _cameraController.position.value;
    if (target == null) return;
    context.read<LocationPickerBloc>().add(
      LocationPickerCameraIdle(target),
    );
  }

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      if (!mounted) return;
      context.read<LocationPickerBloc>().add(
        LocationPickerQueryChanged(query),
      );
    });
  }

  void _onPredictionTap(PlacePrediction prediction) {
    _searchController.clear();
    context.read<LocationPickerBloc>().add(
      LocationPickerPredictionSelected(prediction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final config = widget.configuration;

    return BlocConsumer<LocationPickerBloc, LocationPickerState>(
      listenWhen: (previous, current) =>
          previous.position != current.position ||
          previous.cameraSource != current.cameraSource,
      listener: (context, state) {
        if (state.cameraSource == LocationPickerCameraSource.programmatic &&
            state.position != null) {
          _cameraController.animateTo(
            state.position!,
            zoom: config.initialZoom,
          );
        }
      },
      builder: (context, state) {
        final initialPosition = state.position ?? config.initialPosition;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSearchField(
              controller: _searchController,
              hint: labels.searchHint,
              showMicIcon: false,
              onChanged: _onSearchChanged,
              onSubmitted: (query) {
                _debouncer.cancel();
                context.read<LocationPickerBloc>().add(
                  const LocationPickerPredictionsCleared(),
                );
                context.read<LocationPickerBloc>().add(
                  LocationPickerSearchSubmitted(query),
                );
              },
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              height: responsiveDimension(320),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  responsiveDimension(20),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AppGoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initialPosition,
                        zoom: config.initialZoom,
                      ),
                      onMapCreated: _cameraController.onMapCreated,
                      onCameraMove: _cameraController.onCameraMove,
                      onCameraIdle: _onCameraIdle,
                      myLocationEnabled: state.position != null,
                      tiltGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                    ),
                    IgnorePointer(
                      child: widget.pinMarker ??
                          AppSvgPicture.asset(
                            AppSvgs.mapPinMarker,
                            width: responsiveDimension(48),
                            height: responsiveDimension(64),
                          ),
                    ),
                    if (state.isLoadingMap)
                      ColoredBox(
                        color: context.appColors.surface.withValues(
                          alpha: 0.6,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (state.isGeocoding && !state.isLoadingMap)
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    if (state.hasPredictions)
                      Positioned.fill(
                        child: _PredictionsOverlay(
                          predictions: state.predictions,
                          onTap: _onPredictionTap,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            if (state.hasPermissionError)
              _PermissionMessage(state: state, labels: labels)
            else if (state.status == LocationPickerStatus.failure)
              _ErrorMessage(failure: state.failure, labels: labels)
            else
              _LocationAddressField(
                label: labels.specifiedLocation,
                value: state.address,
                hint: labels.addressHint,
              ),
            SizedBox(height: AppSpacing.md),
            AppButton(
              label: labels.confirm,
              onPressed: state.canConfirm
                  ? () {
                      final position = state.position;
                      final address = state.address;
                      if (position == null || address == null) return;
                      Navigator.of(context).pop(
                        LocationPickerResult(
                          position: position,
                          address: address,
                        ),
                      );
                    }
                  : null,
            ),
          ],
        );
      },
    );
  }
}

class _PredictionsOverlay extends StatelessWidget {
  const _PredictionsOverlay({
    required this.predictions,
    required this.onTap,
  });

  final List<PlacePrediction> predictions;
  final ValueChanged<PlacePrediction> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return ColoredBox(
      color: colors.surface.withValues(alpha: 0.95),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: predictions.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final prediction = predictions[index];
          return InkWell(
            onTap: () => onTap(prediction),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: responsiveDimension(20),
                    color: colors.onSurfaceVariant,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          prediction.mainText,
                          style: typography.regularNormal.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (prediction.secondaryText.isNotEmpty)
                          Text(
                            prediction.secondaryText,
                            style: typography.smallNormal.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LocationAddressField extends StatelessWidget {
  const _LocationAddressField({
    required this.label,
    required this.hint,
    this.value,
  });

  final String label;
  final String? value;
  final String hint;

  bool get _hasValue => value != null && value!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final fieldHeight = responsiveDimension(80);
    final labelGap = responsiveDimension(FieldTokens.labelGap);
    final iconSize = AppDimension.iconLg;

    final displayStyle = _hasValue
        ? FieldTokens.valueStyle(
            typography,
            colors,
            brightness,
            enabled: true,
          )
        : FieldTokens.hintStyle(
            typography,
            colors,
            brightness,
            enabled: true,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: FieldTokens.labelStyle(typography, colors, brightness),
        ),
        SizedBox(height: labelGap),
        Material(
          color: FieldTokens.background(colors, brightness, enabled: true),
          shape: RoundedRectangleBorder(
            borderRadius: FieldTokens.borderRadiusAll(),
            side: BorderSide(
              color: FieldTokens.borderDefault(colors, brightness),
              width: responsiveDimension(FieldTokens.borderWidthDefault),
            ),
          ),
          child: SizedBox(
            height: fieldHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsiveDimension(FieldTokens.horizontalPadding),
                vertical: responsiveDimension(FieldTokens.verticalPadding),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSvgPicture.asset(
                    AppSvgs.map,
                    width: iconSize,
                    height: iconSize,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _hasValue ? value! : hint,
                      style: displayStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionMessage extends StatelessWidget {
  const _PermissionMessage({
    required this.state,
    required this.labels,
  });

  final LocationPickerState state;
  final LocationPickerLabels labels;

  @override
  Widget build(BuildContext context) {
    final message = switch (state.status) {
      LocationPickerStatus.permissionDenied => labels.permissionDenied,
      LocationPickerStatus.permissionPermanentlyDenied =>
        labels.permissionPermanentlyDenied,
      LocationPickerStatus.serviceDisabled => labels.serviceDisabled,
      _ => labels.genericError,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: context.appTypography.regularNormal.copyWith(
            color: context.appColors.error,
          ),
        ),
        if (state.status ==
            LocationPickerStatus.permissionPermanentlyDenied) ...[
          SizedBox(height: AppSpacing.sm),
          AppButton(
            label: labels.openSettings,
            type: AppButtonType.secondary,
            onPressed: () {
              context.read<LocationPickerBloc>().add(
                const LocationPickerSettingsRequested(),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({
    required this.labels,
    this.failure,
  });

  final Failure? failure;
  final LocationPickerLabels labels;

  @override
  Widget build(BuildContext context) {
    return Text(
      failure?.message ?? labels.genericError,
      style: context.appTypography.regularNormal.copyWith(
        color: context.appColors.error,
      ),
    );
  }
}
