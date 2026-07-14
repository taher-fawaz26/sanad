import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/presentation/bloc/location_picker/location_picker_bloc.dart';
import 'package:maps/src/presentation/controllers/map_camera_controller.dart';
import 'package:maps/src/presentation/models/location_picker_labels.dart';
import 'package:maps/src/presentation/models/location_picker_result.dart';
import 'package:maps/src/presentation/models/map_configuration.dart';
import 'package:maps/src/presentation/models/place_search_status.dart';
import 'package:maps/src/presentation/widgets/map_control_bar.dart';
import 'package:maps/src/presentation/widgets/map_my_location_button.dart';
import 'package:maps/src/presentation/widgets/map_zoom_controls.dart';
import 'package:maps/src/presentation/widgets/place_search_bar.dart';
import 'package:maps/src/widgets/app_google_map.dart';

class MapLocationPicker extends StatefulWidget {
  const MapLocationPicker({
    required this.labels,
    this.initialPosition,
    this.initialAddress,
    this.configuration = const MapConfiguration(),
    this.pinMarker,
    this.mapHeight = 320,
    this.showSearchBar = true,
    this.showControls = true,
    this.showConfirmButton = true,
    this.showAddressField = true,
    this.onLocationChanged,
    this.onConfirmed,
    super.key,
  });

  final LocationPickerLabels labels;
  final LatLng? initialPosition;
  final String? initialAddress;
  final MapConfiguration configuration;
  final Widget? pinMarker;
  final double mapHeight;
  final bool showSearchBar;
  final bool showControls;
  final bool showConfirmButton;
  final bool showAddressField;
  final ValueChanged<LocationPickerResult>? onLocationChanged;
  final ValueChanged<LocationPickerResult>? onConfirmed;

  @override
  State<MapLocationPicker> createState() => MapLocationPickerState();
}

class MapLocationPickerState extends State<MapLocationPicker> {
  final _cameraController = MapCameraController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _cameraController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _dismissSearch() {
    _searchFocusNode.unfocus();
  }

  void _onMapTap(LatLng _) {
    _dismissSearch();
  }

  void _onCameraIdle(LocationPickerBloc bloc, LocationPickerState state) {
    if (_cameraController.isAnimating.value) return;
    final target = _cameraController.position.value;
    if (target == null) return;
    bloc.add(LocationPickerCameraIdle(target));
  }

  @override
  Widget build(BuildContext context) {
    final localeIdentifier = Localizations.localeOf(context).toString();

    return BlocProvider(
      create: (_) => sl<LocationPickerBloc>()
        ..add(
          LocationPickerStarted(
            initialPosition: widget.initialPosition,
            initialAddress: widget.initialAddress,
            localeIdentifier: localeIdentifier,
          ),
        ),
      child: BlocListener<LocationPickerBloc, LocationPickerState>(
        listenWhen: (previous, current) =>
            previous.position != current.position ||
            previous.address != current.address ||
            previous.cameraSource != current.cameraSource,
        listener: (context, state) {
          if (state.cameraSource == LocationPickerCameraSource.programmatic &&
              state.position != null) {
            _cameraController.animateTo(
              state.position!,
              zoom: widget.configuration.initialZoom,
            );
          }
          if (state.position != null &&
              state.address != null &&
              state.address!.isNotEmpty) {
            widget.onLocationChanged?.call(
              LocationPickerResult(
                position: state.position!,
                address: state.address!,
              ),
            );
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showSearchBar) _buildSearchBar(),
            if (widget.showSearchBar) SizedBox(height: AppSpacing.md),
            _buildMap(),
            SizedBox(height: AppSpacing.md),
            if (widget.showAddressField) _buildAddressOrError(),
            if (widget.showAddressField && widget.showConfirmButton)
              SizedBox(height: AppSpacing.md),
            if (widget.showConfirmButton) _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return BlocSelector<LocationPickerBloc, LocationPickerState, _SearchState>(
      selector: (state) => _SearchState(
        predictions: state.predictions,
        searchStatus: state.searchStatus,
        searchError: state.searchError,
        searchQuery: state.searchQuery,
      ),
      builder: (context, searchState) {
        final bloc = context.read<LocationPickerBloc>();
        return PlaceSearchBar(
          focusNode: _searchFocusNode,
          hint: widget.labels.searchHint,
          predictions: searchState.predictions,
          searchStatus: searchState.searchStatus,
          searchQuery: searchState.searchQuery,
          errorMessage: searchState.searchError,
          onQueryChanged: (query) {
            bloc.add(LocationPickerQueryChanged(query));
          },
          onSubmitted: (query) {
            bloc
              ..add(const LocationPickerPredictionsCleared())
              ..add(LocationPickerSearchSubmitted(query));
          },
          onPredictionSelected: (prediction) {
            bloc.add(LocationPickerPredictionSelected(prediction));
          },
          onCleared: () {
            bloc.add(const LocationPickerPredictionsCleared());
          },
        );
      },
    );
  }

  Widget _buildMap() {
    return BlocSelector<LocationPickerBloc, LocationPickerState, _MapState>(
      selector: (state) => _MapState(
        position: state.position,
        isLoadingMap: state.isLoadingMap,
        isGeocoding: state.isGeocoding,
      ),
      builder: (context, mapState) {
        final bloc = context.read<LocationPickerBloc>();
        final state = bloc.state;
        return _MapView(
          position: mapState.position,
          isLoadingMap: mapState.isLoadingMap,
          isGeocoding: mapState.isGeocoding,
          configuration: widget.configuration,
          cameraController: _cameraController,
          pinMarker: widget.pinMarker,
          height: widget.mapHeight,
          showControls: widget.showControls,
          onMapTap: _onMapTap,
          onCameraIdle: () => _onCameraIdle(bloc, state),
        );
      },
    );
  }

  Widget _buildAddressOrError() {
    return BlocBuilder<LocationPickerBloc, LocationPickerState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.address != current.address ||
          previous.failure != current.failure,
      builder: (context, state) {
        final labels = widget.labels;

        if (state.hasPermissionError) {
          return _PermissionMessage(state: state, labels: labels);
        }
        if (state.status == LocationPickerStatus.failure) {
          return _ErrorMessage(failure: state.failure, labels: labels);
        }
        return _LocationAddressField(
          label: labels.specifiedLocation,
          value: state.address,
          hint: labels.addressHint,
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    return BlocSelector<LocationPickerBloc, LocationPickerState, bool>(
      selector: (state) => state.canConfirm,
      builder: (context, canConfirm) {
        return AppButton(
          label: widget.labels.confirm,
          onPressed: canConfirm
              ? () {
                  final state = context.read<LocationPickerBloc>().state;
                  final position = state.position;
                  final address = state.address;
                  if (position == null || address == null) return;
                  widget.onConfirmed?.call(
                    LocationPickerResult(
                      position: position,
                      address: address,
                    ),
                  );
                }
              : null,
        );
      },
    );
  }
}

class _SearchState extends Equatable {
  const _SearchState({
    required this.predictions,
    required this.searchStatus,
    required this.searchQuery,
    this.searchError,
  });

  final List<PlacePrediction> predictions;
  final PlaceSearchStatus searchStatus;
  final String searchQuery;
  final String? searchError;

  @override
  List<Object?> get props => [
        predictions,
        searchStatus,
        searchQuery,
        searchError,
      ];
}

class _MapState extends Equatable {
  const _MapState({
    required this.position,
    required this.isLoadingMap,
    required this.isGeocoding,
  });

  final LatLng? position;
  final bool isLoadingMap;
  final bool isGeocoding;

  @override
  List<Object?> get props => [position, isLoadingMap, isGeocoding];
}

class _MapView extends StatelessWidget {
  const _MapView({
    required this.configuration,
    required this.cameraController,
    required this.height,
    required this.showControls,
    required this.onMapTap,
    required this.onCameraIdle,
    required this.isLoadingMap,
    required this.isGeocoding,
    this.position,
    this.pinMarker,
  });

  final LatLng? position;
  final bool isLoadingMap;
  final bool isGeocoding;
  final MapConfiguration configuration;
  final MapCameraController cameraController;
  final Widget? pinMarker;
  final double height;
  final bool showControls;
  final ValueChanged<LatLng> onMapTap;
  final VoidCallback onCameraIdle;

  @override
  Widget build(BuildContext context) {
    final initialPosition = position ?? configuration.initialPosition;
    final colors = context.appColors;

    return SizedBox(
      height: responsiveDimension(height),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(responsiveDimension(20)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AppGoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: configuration.initialZoom,
              ),
              onMapCreated: cameraController.onMapCreated,
              onCameraMove: cameraController.onCameraMove,
              onCameraIdle: onCameraIdle,
              onTap: onMapTap,
              myLocationEnabled: position != null,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
            ),
            IgnorePointer(
              child: pinMarker ??
                  AppSvgPicture.asset(
                    AppSvgs.mapPinMarker,
                    width: responsiveDimension(48),
                    height: responsiveDimension(64),
                  ),
            ),
            if (showControls)
              MapControlBar(
                children: [
                  MapZoomControls(cameraController: cameraController),
                  MapMyLocationButton(
                    cameraController: cameraController,
                    getCurrentLocationUseCase: sl<GetCurrentLocationUseCase>(),
                  ),
                ],
              ),
            if (isLoadingMap)
              Positioned.fill(
                child: ColoredBox(
                  color: colors.surface.withValues(alpha: 0.6),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            if (isGeocoding && !isLoadingMap)
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
              ),
          ],
        ),
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
