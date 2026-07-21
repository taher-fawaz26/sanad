import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/map_area_picker_result.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/presentation/bloc/map_area_picker/map_area_picker_bloc.dart';
import 'package:maps/src/presentation/camera/initial_camera_resolver.dart';
import 'package:maps/src/presentation/controllers/map_camera_controller.dart';
import 'package:maps/src/presentation/models/map_area_picker_labels.dart';
import 'package:maps/src/presentation/models/map_configuration.dart';
import 'package:maps/src/presentation/widgets/location_address_field.dart';
import 'package:maps/src/presentation/widgets/map_control_bar.dart';
import 'package:maps/src/presentation/widgets/map_zoom_controls.dart';
import 'package:maps/src/presentation/widgets/place_search_sheet_body.dart';
import 'package:maps/src/widgets/app_google_map.dart';

/// Reusable map picker that returns a single generic result.
///
/// Visually matches the location picker but without GPS / My Location.
class MapAreaPicker extends StatefulWidget {
  const MapAreaPicker({
    required this.labels,
    this.existingLocation,
    this.initialLocation,
    this.initialAddress,
    this.localeIdentifier,
    this.configuration = const MapConfiguration(),
    this.pinMarker,
    this.mapHeight = 320,
    this.onConfirmed,
    this.requirePlaceId = false,
    super.key,
  });

  final MapAreaPickerLabels labels;

  /// A previously saved location (edit flow). Highest priority for the initial
  /// camera. See [InitialCameraResolver].
  final LatLng? existingLocation;

  /// An explicit initial location supplied by the caller.
  final LatLng? initialLocation;
  final String? initialAddress;
  final String? localeIdentifier;
  final MapConfiguration configuration;
  final Widget? pinMarker;
  final double mapHeight;
  final ValueChanged<MapAreaPickerResult>? onConfirmed;

  /// When true, the confirm button is disabled unless the current location
  /// was selected from search results (i.e. has a real Google Place ID).
  final bool requirePlaceId;

  @override
  State<MapAreaPicker> createState() => _MapAreaPickerState();
}

class _MapAreaPickerState extends State<MapAreaPicker> {
  final _cameraController = MapCameraController();

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng latLng) {
    _cameraController.animateTo(
      latLng,
      zoom: widget.configuration.initialZoom,
    );
  }

  /// Opens the tap-to-search modal sheet. Typing only updates predictions;
  /// selecting a result closes the sheet and dispatches the existing
  /// prediction-selected flow, which animates the camera once.
  Future<void> _openSearchSheet(BuildContext context) async {
    final bloc = context.read<MapAreaPickerBloc>();
    final selected = await showAppModalSheet<PlacePrediction>(
      context: context,
      child: BlocProvider.value(
        value: bloc,
        child: BlocBuilder<MapAreaPickerBloc, MapAreaPickerState>(
          builder: (context, state) => PlaceSearchSheetBody(
            labels: PlaceSearchSheetLabels(
              hint: widget.labels.searchHint,
              emptyMessage: widget.labels.noResultsMessage,
              errorMessage: widget.labels.searchError,
              retryLabel: widget.labels.searchRetry,
            ),
            predictions: state.predictions,
            searchStatus: state.searchStatus,
            searchQuery: state.searchQuery,
            errorMessage: state.searchError,
            onQueryChanged: (q) => context.read<MapAreaPickerBloc>().add(
              MapAreaPickerQueryChanged(q),
            ),
            onPredictionTap: (p) => Navigator.of(context).pop(p),
          ),
        ),
      ),
    );
    bloc.add(const MapAreaPickerPredictionsCleared());
    if (selected != null) {
      bloc.add(MapAreaPickerPredictionSelected(selected));
    }
  }

  void _onCameraIdle(MapAreaPickerBloc bloc) {
    if (_cameraController.isAnimating.value) return;
    final target = _cameraController.position.value;
    if (target == null) return;
    bloc.add(MapAreaPickerLocationChanged(target));
  }

  @override
  Widget build(BuildContext context) {
    final localeIdentifier =
        widget.localeIdentifier ?? Localizations.localeOf(context).toString();

    return BlocProvider(
      create: (_) => sl<MapAreaPickerBloc>()
        ..add(
          MapAreaPickerStarted(
            initialPosition: InitialCameraResolver.resolveInitialLocation(
              existingLocation: widget.existingLocation,
              initialLocation: widget.initialLocation,
            ),
            initialAddress: widget.initialAddress,
            localeIdentifier: localeIdentifier,
          ),
        ),
      child: MultiBlocListener(
        listeners: [
          BlocListener<MapAreaPickerBloc, MapAreaPickerState>(
            listenWhen: (previous, current) =>
                previous.position != current.position ||
                previous.cameraSource != current.cameraSource,
            listener: (context, state) {
              if (state.cameraSource ==
                      MapAreaPickerCameraSource.programmatic &&
                  state.position != null) {
                _cameraController.animateTo(
                  state.position!,
                  zoom: widget.configuration.initialZoom,
                );
              }
            },
          ),
          BlocListener<MapAreaPickerBloc, MapAreaPickerState>(
            listenWhen: (prev, curr) =>
                prev.pickedResult != curr.pickedResult &&
                curr.pickedResult != null,
            listener: (context, state) {
              widget.onConfirmed?.call(state.pickedResult!);
            },
          ),
        ],
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchBar(),
              SizedBox(height: AppSpacing.md),
              _buildMap(),
              SizedBox(height: AppSpacing.md),
              _buildAddressOrError(),
              SizedBox(height: AppSpacing.md),
              _buildConfirmButton(),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    // Tap-to-open trigger — the live search lives in the modal sheet.
    return Builder(
      builder: (context) => AppSearchField(
        variant: AppSearchFieldVariant.bordered,
        hint: widget.labels.searchHint,
        showMicIcon: false,
        readOnly: true,
        onTap: () => _openSearchSheet(context),
      ),
    );
  }

  Widget _buildMap() {
    return BlocSelector<MapAreaPickerBloc, MapAreaPickerState, _MapState>(
      selector: (state) => _MapState(
        position: state.position,
        isGeocoding: state.isGeocoding,
      ),
      builder: (context, mapState) {
        final bloc = context.read<MapAreaPickerBloc>();
        return _MapAreaPickerMapView(
          position: mapState.position,
          isGeocoding: mapState.isGeocoding,
          initialCameraPosition: InitialCameraResolver.resolveCamera(
            existingLocation: widget.existingLocation,
            initialLocation: widget.initialLocation,
            zoom: widget.configuration.initialZoom,
          ),
          cameraController: _cameraController,
          pinMarker: widget.pinMarker,
          height: widget.mapHeight,
          onMapTap: _onMapTap,
          onCameraIdle: () => _onCameraIdle(bloc),
        );
      },
    );
  }

  Widget _buildAddressOrError() {
    return BlocBuilder<MapAreaPickerBloc, MapAreaPickerState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.address != current.address ||
          previous.failure != current.failure,
      builder: (context, state) {
        final labels = widget.labels;

        if (state.status == MapAreaPickerStatus.failure) {
          return _MapAreaPickerErrorMessage(
            failure: state.failure,
            labels: labels,
          );
        }
        return LocationAddressField(
          label: labels.specifiedLocation,
          value: state.address,
          hint: labels.addressHint,
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    return BlocBuilder<MapAreaPickerBloc, MapAreaPickerState>(
      buildWhen: (prev, curr) =>
          prev.canConfirm != curr.canConfirm ||
          prev.selectedPlaceId != curr.selectedPlaceId,
      builder: (context, state) {
        final hasPlaceId = state.selectedPlaceId != null;
        final enabled =
            state.canConfirm && (!widget.requirePlaceId || hasPlaceId);
        final showHint =
            widget.requirePlaceId &&
            state.canConfirm &&
            !hasPlaceId &&
            widget.labels.placeIdRequiredHint != null;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHint)
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  widget.labels.placeIdRequiredHint!,
                  style: context.appTypography.smallNormal.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            AppButton(
              label: widget.labels.confirm,
              onPressed: enabled
                  ? () {
                      context.read<MapAreaPickerBloc>().add(
                        const MapAreaPickerConfirmed(),
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

class _MapState extends Equatable {
  const _MapState({
    required this.position,
    required this.isGeocoding,
  });

  final LatLng? position;
  final bool isGeocoding;

  @override
  List<Object?> get props => [position, isGeocoding];
}

class _MapAreaPickerMapView extends StatelessWidget {
  const _MapAreaPickerMapView({
    required this.initialCameraPosition,
    required this.cameraController,
    required this.height,
    required this.onMapTap,
    required this.onCameraIdle,
    required this.isGeocoding,
    this.position,
    this.pinMarker,
  });

  final LatLng? position;
  final bool isGeocoding;
  final CameraPosition initialCameraPosition;
  final MapCameraController cameraController;
  final Widget? pinMarker;
  final double height;
  final ValueChanged<LatLng> onMapTap;
  final VoidCallback onCameraIdle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: responsiveDimension(height),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(responsiveDimension(20)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AppGoogleMap(
              initialCameraPosition: initialCameraPosition,
              onMapCreated: cameraController.onMapCreated,
              onCameraMove: cameraController.onCameraMove,
              onCameraIdle: onCameraIdle,
              onTap: onMapTap,
              myLocationEnabled: position != null,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
            ),
            IgnorePointer(
              child:
                  pinMarker ??
                  AppSvgPicture.asset(
                    AppSvgs.mapPinMarker,
                    width: responsiveDimension(48),
                    height: responsiveDimension(64),
                  ),
            ),
            MapControlBar(
              children: [
                MapZoomControls(cameraController: cameraController),
              ],
            ),
            if (isGeocoding)
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: const AppLoadingIndicator(size: 20, strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapAreaPickerErrorMessage extends StatelessWidget {
  const _MapAreaPickerErrorMessage({
    required this.labels,
    this.failure,
  });

  final Failure? failure;
  final MapAreaPickerLabels labels;

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

/// Shows [MapAreaPicker] in a bottom sheet and resolves to the chosen
/// [MapAreaPickerResult], or `null` if dismissed without confirming.
Future<MapAreaPickerResult?> showMapAreaPicker(
  BuildContext context, {
  required MapAreaPickerLabels labels,
  LatLng? existingLocation,
  LatLng? initialLocation,
  String? initialAddress,
  String? localeIdentifier,
  MapConfiguration configuration = const MapConfiguration(),
  Widget? pinMarker,
  bool requirePlaceId = false,
}) {
  return showAppBottomSheet<MapAreaPickerResult>(
    context: context,
    title: labels.title,
    showDragHandle: false,
    child: Builder(
      builder: (sheetContext) => MapAreaPicker(
        labels: labels,
        existingLocation: existingLocation,
        initialLocation: initialLocation,
        initialAddress: initialAddress,
        localeIdentifier: localeIdentifier,
        configuration: configuration,
        pinMarker: pinMarker,
        requirePlaceId: requirePlaceId,
        onConfirmed: (result) => Navigator.of(sheetContext).pop(result),
      ),
    ),
  );
}
