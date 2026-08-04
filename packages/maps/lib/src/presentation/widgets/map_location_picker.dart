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
import 'package:maps/src/presentation/camera/default_map_viewport.dart';
import 'package:maps/src/presentation/camera/initial_camera_resolver.dart';
import 'package:maps/src/presentation/controllers/map_camera_controller.dart';
import 'package:maps/src/presentation/models/location_picker_labels.dart';
import 'package:maps/src/presentation/models/location_picker_result.dart';
import 'package:maps/src/presentation/models/map_configuration.dart';
import 'package:maps/src/presentation/widgets/location_address_field.dart';
import 'package:maps/src/presentation/widgets/map_control_bar.dart';
import 'package:maps/src/presentation/widgets/map_my_location_button.dart';
import 'package:maps/src/presentation/widgets/map_zoom_controls.dart';
import 'package:maps/src/presentation/widgets/place_search_sheet_body.dart';
import 'package:maps/src/widgets/app_google_map.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

class MapLocationPicker extends StatefulWidget {
  const MapLocationPicker({
    required this.labels,
    this.existingLocation,
    this.initialLocation,
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

  /// A previously saved location (edit flow). Highest priority for the initial
  /// camera. See [InitialCameraResolver].
  final LatLng? existingLocation;

  /// An explicit initial location supplied by the caller. Used when there is no
  /// [existingLocation].
  final LatLng? initialLocation;
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

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  /// Opens the tap-to-search modal sheet, mirroring the Branches/Workers search
  /// UX. Typing only updates predictions (never the camera); selecting a result
  /// closes the sheet and dispatches the existing prediction-selected flow,
  /// which animates the camera exactly once.
  Future<void> _openSearchSheet(BuildContext context) async {
    final bloc = context.read<LocationPickerBloc>();
    final selected = await SheetNavigator.push<PlacePrediction>(
      context,
      BlocProvider.value(
        value: bloc,
        child: BlocBuilder<LocationPickerBloc, LocationPickerState>(
          builder: (context, state) => PlaceSearchSheetBody(
            labels: PlaceSearchSheetLabels(
              hint: widget.labels.searchHint,
              emptyMessage: widget.labels.searchEmpty,
              errorMessage: widget.labels.genericError,
              retryLabel: widget.labels.searchRetry,
            ),
            predictions: state.predictions,
            searchStatus: state.searchStatus,
            searchQuery: state.searchQuery,
            errorMessage: state.searchError,
            onQueryChanged: (q) => context.read<LocationPickerBloc>().add(
              LocationPickerQueryChanged(q),
            ),
            onPredictionTap: (p) => Navigator.of(context).pop(p),
          ),
        ),
      ),
      settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
    );
    bloc.add(const LocationPickerPredictionsCleared());
    if (selected != null) {
      bloc.add(LocationPickerPredictionSelected(selected));
    }
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
            initialPosition: InitialCameraResolver.resolveInitialLocation(
              existingLocation: widget.existingLocation,
              initialLocation: widget.initialLocation,
            ),
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
          initialCameraPosition: InitialCameraResolver.resolveCamera(
            existingLocation: widget.existingLocation,
            initialLocation: widget.initialLocation,
            zoom: widget.configuration.initialZoom,
          ),
          cameraController: _cameraController,
          pinMarker: widget.pinMarker,
          height: widget.mapHeight,
          showControls: widget.showControls,
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
        return LocationAddressField(
          label: labels.specifiedLocation,
          value: state.address,
          hint: labels.addressHint,
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    return BlocSelector<
      LocationPickerBloc,
      LocationPickerState,
      ({bool canConfirm, bool isOutsideCountry})
    >(
      selector: (state) => (
        canConfirm: state.canConfirm,
        isOutsideCountry: state.isOutsideCountry,
      ),
      builder: (context, rec) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (rec.isOutsideCountry) ...[
              Text(
                widget.labels.outsideCountry,
                textAlign: TextAlign.center,
                style: context.appTypography.smallNormal.copyWith(
                  color: context.appColors.error,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
            ],
            AppButton(
              label: widget.labels.confirm,
              onPressed: rec.canConfirm
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
    required this.initialCameraPosition,
    required this.cameraController,
    required this.height,
    required this.showControls,
    required this.onCameraIdle,
    required this.isLoadingMap,
    required this.isGeocoding,
    this.position,
    this.pinMarker,
  });

  final LatLng? position;
  final bool isLoadingMap;
  final bool isGeocoding;
  final CameraPosition initialCameraPosition;
  final MapCameraController cameraController;
  final Widget? pinMarker;
  final double height;
  final bool showControls;
  final VoidCallback onCameraIdle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: responsiveDimension(height),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(responsiveDimension(20)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AppGoogleMap(
              initialCameraPosition: initialCameraPosition,
              cameraTargetBounds: CameraTargetBounds(
                DefaultMapViewport.uaeBounds,
              ),
              onMapCreated: cameraController.onMapCreated,
              onCameraMove: cameraController.onCameraMove,
              onCameraIdle: onCameraIdle,
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
                  child: const Center(child: AppLoadingIndicator()),
                ),
              ),
            if (isGeocoding && !isLoadingMap)
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: const AppLoadingIndicator(size: 20),
              ),
          ],
        ),
      ),
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
