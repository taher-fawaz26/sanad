import 'package:app_assets/app_assets.dart';
import 'package:app_logger/app_logger.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/presentation/bloc/location_picker/location_picker_bloc.dart';
import 'package:maps/src/presentation/camera/default_map_viewport.dart';
import 'package:maps/src/services/location_failure_codes.dart';
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
    this.initialPlaceId,
    this.configuration = const MapConfiguration(),
    this.pinMarker,
    this.mapHeight = 320,
    this.showSearchBar = true,
    this.showControls = true,
    this.showConfirmButton = true,
    this.showAddressField = true,
    this.requirePlaceId = false,
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

  /// A previously saved Google Place ID (edit-reopen), seeded so an
  /// already-complete selection is confirmable immediately (SAN-778 follow-up).
  final String? initialPlaceId;
  final MapConfiguration configuration;
  final Widget? pinMarker;
  final double mapHeight;
  final bool showSearchBar;
  final bool showControls;
  final bool showConfirmButton;
  final bool showAddressField;

  /// When true, the location cannot be confirmed unless the current selection
  /// carries a Google Place ID — i.e. it was chosen from search autocomplete.
  /// Dragging the pin, using GPS, or plain geocoding produces coordinates
  /// without a Place ID (see [LocationPickerState.selectedPlaceId]), which some
  /// backends (e.g. branch creation) reject. Off by default so consumers that
  /// only need coordinates keep the existing free-pin behavior.
  final bool requirePlaceId;
  final ValueChanged<LocationPickerResult>? onLocationChanged;
  final ValueChanged<LocationPickerResult>? onConfirmed;

  @override
  State<MapLocationPicker> createState() => MapLocationPickerState();
}

class MapLocationPickerState extends State<MapLocationPicker>
    with WidgetsBindingObserver {
  final _cameraController = MapCameraController();

  /// Held so the app-lifecycle observer can re-check permission on resume.
  /// Owned/closed by the [BlocProvider]; this is only a reference.
  LocationPickerBloc? _bloc;

  /// Gates the real map/Bloc content behind the sheet's first frame.
  ///
  /// GoogleMap's Android PlatformView creation blocks the platform thread
  /// while it bootstraps Google Play Services natively (Dynamite module
  /// load, JNI, EGL context) — this can take multiple seconds. If that
  /// widget is present in the very first build of this (already-expensive)
  /// sheet route, the whole UI — including the sheet's own entrance
  /// animation — freezes with no feedback until it resolves. Staying on a
  /// cheap skeleton for exactly one frame lets the sheet paint first, so the
  /// expensive PlatformView creation happens once something is already
  /// visible on screen. Do NOT remove this gate as a "simplification" — it
  /// is the actual fix, not decoration.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appLogger.d('[MapLocationPicker] sheet first frame rendered');
      if (!mounted) return;
      setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // A location error notification lives in the root overlay, so it would
    // outlive this sheet — dismiss it when the picker closes.
    dismissAppOverlayNotification();
    _bloc = null;
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from system Settings (device location / app permission) must
    // recover the picker without a restart or an arbitrary delay: re-check
    // the OS state and clear any stale current-location error (SAN-778).
    if (state == AppLifecycleState.resumed) {
      _bloc?.add(const LocationPickerResumed());
    }
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
    if (!_ready) {
      return _LocationPickerSkeleton(
        mapHeight: widget.mapHeight,
        showSearchBar: widget.showSearchBar,
        showAddressField: widget.showAddressField,
        showConfirmButton: widget.showConfirmButton,
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final localeIdentifier = Localizations.localeOf(context).toString();
    appLogger.d('[MapLocationPicker] location/map init starting');

    return BlocProvider(
      create: (_) {
        final bloc = sl<LocationPickerBloc>()
          ..add(
            LocationPickerStarted(
              initialPosition: InitialCameraResolver.resolveInitialLocation(
                existingLocation: widget.existingLocation,
                initialLocation: widget.initialLocation,
              ),
              initialAddress: widget.initialAddress,
              initialPlaceId: widget.initialPlaceId,
              localeIdentifier: localeIdentifier,
            ),
          );
        _bloc = bloc;
        return bloc;
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<LocationPickerBloc, LocationPickerState>(
            listenWhen: (previous, current) =>
                previous.position != current.position ||
                previous.address != current.address ||
                previous.cameraSource != current.cameraSource,
            listener: (context, state) {
              if (state.cameraSource ==
                      LocationPickerCameraSource.programmatic &&
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
                    placeId: state.selectedPlaceId,
                  ),
                );
              }
            },
          ),
          // Every location failure is surfaced as a top-of-screen
          // notification rendered in the ROOT overlay, so it stays visible
          // ABOVE this modal bottom sheet — a ScaffoldMessenger snackbar would
          // anchor to the underlying page's Scaffold and be hidden behind the
          // sheet. The failed attempt never hides/replaces a valid selection
          // (SAN-778): the sheet stays open and the map state is untouched.
          BlocListener<LocationPickerBloc, LocationPickerState>(
            listenWhen: (previous, current) =>
                previous.currentLocationFailure !=
                    current.currentLocationFailure &&
                current.currentLocationFailure != null,
            listener: (context, state) => _showLocationErrorNotification(
              context,
              state.currentLocationFailure!,
              isCurrentLocation: true,
            ),
          ),
          // Reverse/forward-geocode + Place-ID resolution failures (network,
          // no place found, API errors) surface through the same top
          // notification instead of an inline panel under the sheet.
          BlocListener<LocationPickerBloc, LocationPickerState>(
            listenWhen: (previous, current) =>
                previous.failure != current.failure &&
                current.status == LocationPickerStatus.failure &&
                current.failure != null,
            listener: (context, state) => _showLocationErrorNotification(
              context,
              state.failure!,
              isCurrentLocation: false,
            ),
          ),
        ],
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
        hasLocationPermission: state.hasLocationPermission,
        isLocating: state.isLocating,
      ),
      builder: (context, mapState) {
        final bloc = context.read<LocationPickerBloc>();
        final state = bloc.state;
        return _MapView(
          position: mapState.position,
          isLoadingMap: mapState.isLoadingMap,
          isGeocoding: mapState.isGeocoding,
          hasLocationPermission: mapState.hasLocationPermission,
          isLocating: mapState.isLocating,
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
          onMyLocationPressed: () =>
              bloc.add(const LocationPickerCurrentLocationRequested()),
        );
      },
    );
  }

  Widget _buildAddressOrError() {
    return BlocBuilder<LocationPickerBloc, LocationPickerState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.address != current.address,
      builder: (context, state) {
        final labels = widget.labels;
        // The sheet content only ever shows the (read-only) address field —
        // the resolved address when there is a valid selection, otherwise the
        // hint. Failures are surfaced as a top-of-screen notification above
        // the sheet (see the failure listeners in `_buildContent`), never
        // inline under the sheet, and never by disabling the field. Progress
        // is conveyed by the map spinner and the disabled Confirm button.
        return LocationAddressField(
          label: labels.specifiedLocation,
          value: state.hasResolvedSelection ? state.address : null,
          hint: labels.addressHint,
        );
      },
    );
  }

  /// Surfaces a location [failure] as a top-of-screen notification rendered in
  /// the root overlay — visible ABOVE this modal bottom sheet. The message is
  /// localized by the stable failure [code] (never a raw platform exception),
  /// and the single recovery action retries or opens the appropriate settings.
  /// Repeated failures replace the active notification rather than stacking.
  void _showLocationErrorNotification(
    BuildContext context,
    Failure failure, {
    required bool isCurrentLocation,
  }) {
    final labels = widget.labels;
    final bloc = context.read<LocationPickerBloc>();
    final action = _locationErrorActionFor(failure.code);

    showAppOverlayNotification(
      context: context,
      title: _locationErrorMessageFor(failure.code, labels),
      action: AppSnackbarAction.text,
      actionLabel: switch (action) {
        _LocationErrorAction.openAppSettings => labels.openSettings,
        _LocationErrorAction.openLocationSettings =>
          labels.openLocationSettings,
        _LocationErrorAction.retry => labels.retry,
      },
      onAction: () {
        if (bloc.isClosed) return;
        switch (action) {
          case _LocationErrorAction.openAppSettings:
            bloc.add(const LocationPickerSettingsRequested());
          case _LocationErrorAction.openLocationSettings:
            bloc.add(const LocationPickerDeviceSettingsRequested());
          case _LocationErrorAction.retry:
            bloc.add(
              isCurrentLocation
                  ? const LocationPickerCurrentLocationRequested()
                  : const LocationPickerRetryGeocode(),
            );
        }
      },
    );
  }

  Widget _buildConfirmButton() {
    return BlocSelector<
      LocationPickerBloc,
      LocationPickerState,
      ({bool canConfirm, bool isOutsideCountry, bool hasPlaceId})
    >(
      selector: (state) => (
        canConfirm: state.canConfirm,
        isOutsideCountry: state.isOutsideCountry,
        hasPlaceId: state.selectedPlaceId != null,
      ),
      builder: (context, rec) {
        final enabled =
            rec.canConfirm && (!widget.requirePlaceId || rec.hasPlaceId);
        // Prompt to pick from search only when everything else is valid but the
        // selection lacks the required Place ID (dragged pin / GPS / geocode).
        final showPlaceIdHint =
            widget.requirePlaceId &&
            rec.canConfirm &&
            !rec.hasPlaceId &&
            widget.labels.placeIdRequiredHint != null;
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
            if (showPlaceIdHint) ...[
              Text(
                widget.labels.placeIdRequiredHint!,
                textAlign: TextAlign.center,
                style: context.appTypography.smallNormal.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
            ],
            AppButton(
              label: widget.labels.confirm,
              onPressed: enabled
                  ? () {
                      final state = context.read<LocationPickerBloc>().state;
                      final position = state.position;
                      final address = state.address;
                      if (position == null || address == null) return;
                      if (widget.requirePlaceId &&
                          state.selectedPlaceId == null) {
                        return;
                      }
                      widget.onConfirmed?.call(
                        LocationPickerResult(
                          position: position,
                          address: address,
                          placeId: state.selectedPlaceId,
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

/// Cheap placeholder painted for exactly one frame while [MapLocationPicker]
/// waits for the sheet's first frame — see [MapLocationPickerState._ready].
/// Contains no Bloc, no [AppGoogleMap]: nothing here can trigger the
/// expensive native PlatformView bootstrap.
class _LocationPickerSkeleton extends StatelessWidget {
  const _LocationPickerSkeleton({
    required this.mapHeight,
    required this.showSearchBar,
    required this.showAddressField,
    required this.showConfirmButton,
  });

  final double mapHeight;
  final bool showSearchBar;
  final bool showAddressField;
  final bool showConfirmButton;

  Widget _block({required double height, double? width}) {
    return AppShimmer(
      child: Builder(
        builder: (context) => Container(
          width: width,
          height: responsiveDimension(height),
          decoration: BoxDecoration(
            color: context.appColors.onBackground,
            borderRadius: BorderRadius.circular(responsiveDimension(12)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSearchBar) ...[
          _block(height: 48),
          SizedBox(height: AppSpacing.md),
        ],
        _block(height: mapHeight),
        SizedBox(height: AppSpacing.md),
        if (showAddressField) ...[
          _block(height: 56),
          if (showConfirmButton) SizedBox(height: AppSpacing.md),
        ],
        if (showConfirmButton) _block(height: 48),
      ],
    );
  }
}

class _MapState extends Equatable {
  const _MapState({
    required this.position,
    required this.isLoadingMap,
    required this.isGeocoding,
    required this.hasLocationPermission,
    required this.isLocating,
  });

  final LatLng? position;
  final bool isLoadingMap;
  final bool isGeocoding;
  final bool hasLocationPermission;
  final bool isLocating;

  @override
  List<Object?> get props => [
    position,
    isLoadingMap,
    isGeocoding,
    hasLocationPermission,
    isLocating,
  ];
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
    required this.hasLocationPermission,
    required this.isLocating,
    required this.onMyLocationPressed,
    this.position,
    this.pinMarker,
  });

  final LatLng? position;
  final bool isLoadingMap;
  final bool isGeocoding;

  /// Gates [AppGoogleMap.myLocationEnabled] — never enable the MyLocation
  /// layer before permission is actually known to be granted (see
  /// [LocationPickerState.hasLocationPermission]).
  final bool hasLocationPermission;

  /// Whether a current-location request is in flight — drives the crosshair
  /// button's spinner.
  final bool isLocating;
  final CameraPosition initialCameraPosition;
  final MapCameraController cameraController;
  final Widget? pinMarker;
  final double height;
  final bool showControls;
  final VoidCallback onCameraIdle;

  /// Dispatches the "use my current location" request. The whole sequence
  /// (permission/service, GPS, validation, camera, geocode) is owned by the
  /// bloc — see [LocationPickerCurrentLocationRequested].
  final VoidCallback onMyLocationPressed;

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
              onMapCreated: (controller) {
                appLogger.d('[MapLocationPicker] GoogleMap onMapCreated');
                cameraController.onMapCreated(controller);
              },
              onCameraMove: cameraController.onCameraMove,
              onCameraIdle: onCameraIdle,
              myLocationEnabled: hasLocationPermission && position != null,
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
                    isLoading: isLocating,
                    onPressed: onMyLocationPressed,
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

/// The recovery action a location failure offers.
enum _LocationErrorAction { retry, openAppSettings, openLocationSettings }

/// Resolves a location failure [code] to a localized message — never render
/// `failure.message`, which for geocoding/location failures may be a raw
/// platform exception string (e.g. `PlatformException(NOT_FOUND, ...)`) and
/// must never reach the user (SAN-778).
String _locationErrorMessageFor(String? code, LocationPickerLabels labels) =>
    switch (code) {
      LocationFailureCodes.serviceDisabled => labels.serviceDisabled,
      LocationFailureCodes.permissionDenied => labels.permissionDenied,
      LocationFailureCodes.permissionPermanentlyDenied =>
        labels.permissionPermanentlyDenied,
      LocationFailureCodes.outsideSupportedCountry => labels.outsideCountry,
      LocationFailureCodes.timeout => labels.locationTimeout,
      LocationFailureCodes.unavailable => labels.locationUnavailable,
      LocationFailureCodes.geocodingFailed => labels.addressNotFound,
      _ => labels.genericError,
    };

/// The single recovery action appropriate to a location failure [code]:
/// device-location settings for a disabled service, app settings for a
/// permanent permission denial, and a plain retry for everything else.
_LocationErrorAction _locationErrorActionFor(String? code) => switch (code) {
  LocationFailureCodes.serviceDisabled =>
    _LocationErrorAction.openLocationSettings,
  LocationFailureCodes.permissionPermanentlyDenied =>
    _LocationErrorAction.openAppSettings,
  _ => _LocationErrorAction.retry,
};
