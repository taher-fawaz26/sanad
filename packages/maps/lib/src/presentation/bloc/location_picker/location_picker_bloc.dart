import 'dart:async';

import 'package:app_logger/app_logger.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/domain/usecases/check_location_permission_usecase.dart';
import 'package:maps/src/domain/usecases/forward_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/domain/usecases/get_place_details_usecase.dart';
import 'package:maps/src/domain/usecases/open_device_location_settings_usecase.dart';
import 'package:maps/src/domain/usecases/open_location_settings_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_place_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/search_places_usecase.dart';
import 'package:maps/src/presentation/camera/default_map_viewport.dart';
import 'package:maps/src/presentation/models/place_search_status.dart';
import 'package:maps/src/presentation/utils/latest_operation.dart';
import 'package:maps/src/presentation/utils/place_search_runner.dart';
import 'package:maps/src/services/location_failure_codes.dart';
import 'package:maps/src/services/location_service.dart';

part 'location_picker_event.dart';
part 'location_picker_state.dart';

class LocationPickerBloc
    extends Bloc<LocationPickerEvent, LocationPickerState> {
  LocationPickerBloc({
    required ReverseGeocodeUseCase reverseGeocodeUseCase,
    required ForwardGeocodeUseCase forwardGeocodeUseCase,
    required OpenLocationSettingsUseCase openLocationSettingsUseCase,
    GetCurrentLocationUseCase? getCurrentLocationUseCase,
    OpenDeviceLocationSettingsUseCase? openDeviceLocationSettingsUseCase,
    CheckLocationPermissionUseCase? checkLocationPermissionUseCase,
    SearchPlacesUseCase? searchPlacesUseCase,
    GetPlaceDetailsUseCase? getPlaceDetailsUseCase,
    ReverseGeocodePlaceUseCase? reverseGeocodePlaceUseCase,
    LatLngBounds? supportedBounds,
  }) : _reverseGeocodeUseCase = reverseGeocodeUseCase,
       _forwardGeocodeUseCase = forwardGeocodeUseCase,
       _openLocationSettingsUseCase = openLocationSettingsUseCase,
       _getCurrentLocationUseCase = getCurrentLocationUseCase,
       _openDeviceLocationSettingsUseCase = openDeviceLocationSettingsUseCase,
       _checkLocationPermissionUseCase = checkLocationPermissionUseCase,
       _getPlaceDetailsUseCase = getPlaceDetailsUseCase,
       _reverseGeocodePlaceUseCase = reverseGeocodePlaceUseCase,
       _supportedBounds = supportedBounds ?? DefaultMapViewport.uaeBounds,
       _searchRunner = PlaceSearchRunner(
         searchPlacesUseCase: searchPlacesUseCase,
       ),
       super(const LocationPickerState()) {
    on<LocationPickerStarted>(_onStarted);
    on<LocationPickerCameraIdle>(_onCameraIdle);
    on<LocationPickerSearchSubmitted>(_onSearchSubmitted);
    on<LocationPickerSettingsRequested>(_onSettingsRequested);
    on<LocationPickerDeviceSettingsRequested>(_onDeviceSettingsRequested);
    on<LocationPickerQueryChanged>(_onQueryChanged);
    on<LocationPickerPredictionSelected>(_onPredictionSelected);
    on<LocationPickerPredictionsCleared>(_onPredictionsCleared);
    on<LocationPickerPermissionChecked>(_onPermissionChecked);
    on<LocationPickerCurrentLocationRequested>(_onCurrentLocationRequested);
    on<LocationPickerRetryGeocode>(_onRetryGeocode);
    on<LocationPickerResumed>(_onResumed);
  }

  final ReverseGeocodeUseCase _reverseGeocodeUseCase;
  final ForwardGeocodeUseCase _forwardGeocodeUseCase;
  final OpenLocationSettingsUseCase _openLocationSettingsUseCase;
  final GetCurrentLocationUseCase? _getCurrentLocationUseCase;
  final OpenDeviceLocationSettingsUseCase? _openDeviceLocationSettingsUseCase;
  final CheckLocationPermissionUseCase? _checkLocationPermissionUseCase;
  final GetPlaceDetailsUseCase? _getPlaceDetailsUseCase;

  /// Google-only. When present, reverse-geocoding a coordinate (map drag,
  /// current location, forward geocode) also yields a real Google `place_id`,
  /// so those selections carry the Place ID the backend requires — no search
  /// result needed. Null for the platform geocoder / non-Google providers,
  /// which cannot produce a Place ID.
  final ReverseGeocodePlaceUseCase? _reverseGeocodePlaceUseCase;

  /// Supported service area — a resolved GPS position outside this is rejected
  /// (reported, not silently clamped by the camera) so an out-of-country
  /// device never lands on a bogus corner coordinate (SAN-778).
  final LatLngBounds _supportedBounds;
  final PlaceSearchRunner _searchRunner;

  String? _localeIdentifier;

  /// Guards location-producing operations (current location, forward geocode,
  /// place details) and the reverse-geocode that follows them, so only the
  /// latest such sequence updates the state.
  final LatestOperation _geocodeOp = LatestOperation();

  Future<void> _onStarted(
    LocationPickerStarted event,
    Emitter<LocationPickerState> emit,
  ) async {
    appLogger.d('[LocationPickerBloc] started (map/location init begins)');
    _localeIdentifier = event.localeIdentifier;
    final token = _geocodeOp.begin();

    // Fire-and-forget: never let the permission check delay the initial
    // ready/geocoding emission below — myLocationEnabled simply stays false
    // until this resolves and LocationPickerPermissionChecked lands.
    unawaited(_checkPermission());

    if (event.initialPosition != null) {
      final hasAddress =
          event.initialAddress != null && event.initialAddress!.isNotEmpty;
      final hasPlaceId =
          event.initialPlaceId != null && event.initialPlaceId!.isNotEmpty;
      // A reopened selection that already carries an address is shown ready
      // immediately (no re-geocode, no risk of an offline failure blanking a
      // saved location). Its saved Place ID is seeded so Confirm is enabled at
      // once — in the branch flow an address is only ever stored together with
      // its Place ID. With no address, resolve (which also yields a Place ID).
      emit(
        state.copyWith(
          status: hasAddress
              ? LocationPickerStatus.ready
              : LocationPickerStatus.geocoding,
          position: event.initialPosition,
          address: event.initialAddress,
          selectedPlaceId: hasPlaceId ? () => event.initialPlaceId : null,
          cameraSource: LocationPickerCameraSource.programmatic,
          clearFailure: true,
        ),
      );
      if (!hasAddress) {
        await _reverseGeocode(event.initialPosition!, emit, token);
      }
      return;
    }

    // No saved/explicit location: open on the default UAE viewport with no
    // pin and WITHOUT requesting location permission. The device location is
    // only used when the user taps "Use My Current Location"
    // ([MapMyLocationButton]).
    emit(
      state.copyWith(status: LocationPickerStatus.ready, clearFailure: true),
    );
  }

  Future<void> _onCameraIdle(
    LocationPickerCameraIdle event,
    Emitter<LocationPickerState> emit,
  ) async {
    if (state.status == LocationPickerStatus.loadingLocation) return;
    if (state.position == event.position) return;

    final token = _geocodeOp.begin();
    emit(
      state.copyWith(
        status: LocationPickerStatus.geocoding,
        position: event.position,
        cameraSource: LocationPickerCameraSource.user,
        clearFailure: true,
        clearPredictions: true,
        clearSelectedPlaceId: true,
        // Moving the pin is a fresh selection that supersedes any earlier
        // "use my current location" failure — clear it so a stale (e.g.
        // serviceDisabled) error never lingers into this resolution (SAN-778).
        clearCurrentLocationFailure: true,
      ),
    );

    await _reverseGeocode(event.position, emit, token);
  }

  Future<void> _onSearchSubmitted(
    LocationPickerSearchSubmitted event,
    Emitter<LocationPickerState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    // Only forward-geocode when no predictions are available AND
    // the Places provider is disabled. When Places is enabled, the user
    // should explicitly tap a prediction.
    if (_searchRunner.isEnabled && state.hasPredictions) return;

    await _submitViaGeocode(query, emit);
  }

  Future<void> _submitViaGeocode(
    String query,
    Emitter<LocationPickerState> emit,
  ) async {
    final token = _geocodeOp.begin();
    _searchRunner.cancelPending();
    emit(
      state.copyWith(
        status: LocationPickerStatus.geocoding,
        clearFailure: true,
        clearPredictions: true,
        clearSelectedPlaceId: true,
        // A search supersedes any earlier current-location failure.
        clearCurrentLocationFailure: true,
      ),
    );

    final result = await _forwardGeocodeUseCase(
      ForwardGeocodeParams(
        address: query,
        localeIdentifier: _localeIdentifier,
      ),
    ).run();
    if (!_geocodeOp.isCurrent(token)) return;

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: LocationPickerStatus.failure,
            failure: failure,
          ),
        );
      },
      (position) async {
        emit(
          state.copyWith(
            status: LocationPickerStatus.geocoding,
            position: position,
            cameraSource: LocationPickerCameraSource.programmatic,
            clearFailure: true,
          ),
        );
        await _reverseGeocode(position, emit, token);
      },
    );
  }

  Future<void> _onSettingsRequested(
    LocationPickerSettingsRequested event,
    Emitter<LocationPickerState> emit,
  ) async {
    await _openLocationSettingsUseCase(const NoParams()).run();
  }

  Future<void> _onDeviceSettingsRequested(
    LocationPickerDeviceSettingsRequested event,
    Emitter<LocationPickerState> emit,
  ) async {
    await _openDeviceLocationSettingsUseCase?.call(const NoParams()).run();
  }

  Future<void> _onQueryChanged(
    LocationPickerQueryChanged event,
    Emitter<LocationPickerState> emit,
  ) async {
    if (!_searchRunner.isEnabled) return;

    final query = event.query.trim();
    if (query.length < 2) {
      emit(
        state.copyWith(
          clearPredictions: true,
          searchQuery: query,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        searchStatus: PlaceSearchStatus.searching,
        searchQuery: query,
        clearSearchError: true,
      ),
    );

    final result = await _searchRunner.search(
      query: query,
      language: _localeIdentifier,
      biasLocation: state.position,
    );
    if (result == null) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            searchStatus: PlaceSearchStatus.failure,
            searchError: failure.message,
            clearPredictions: true,
          ),
        );
      },
      (predictions) {
        emit(
          state.copyWith(
            predictions: predictions,
            searchStatus: predictions.isEmpty
                ? PlaceSearchStatus.empty
                : PlaceSearchStatus.success,
            clearSearchError: true,
          ),
        );
      },
    );
  }

  Future<void> _onPredictionSelected(
    LocationPickerPredictionSelected event,
    Emitter<LocationPickerState> emit,
  ) async {
    final useCase = _getPlaceDetailsUseCase;
    if (useCase == null) {
      add(LocationPickerSearchSubmitted(event.prediction.description));
      return;
    }

    final token = _geocodeOp.begin();
    final placeId = event.prediction.placeId;
    _searchRunner.cancelPending();
    emit(
      state.copyWith(
        status: LocationPickerStatus.geocoding,
        clearPredictions: true,
        clearFailure: true,
        selectedPlaceId: () => placeId,
        // Choosing a search result supersedes any earlier current-location
        // failure.
        clearCurrentLocationFailure: true,
      ),
    );

    final result = await useCase(
      GetPlaceDetailsParams(placeId: placeId),
    ).run();
    if (!_geocodeOp.isCurrent(token)) return;

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: LocationPickerStatus.failure,
            failure: failure,
          ),
        );
      },
      (position) async {
        emit(
          state.copyWith(
            status: LocationPickerStatus.geocoding,
            position: position,
            cameraSource: LocationPickerCameraSource.programmatic,
            clearFailure: true,
          ),
        );
        // Keep the search prediction's own Place ID — do NOT overwrite it with
        // a reverse-geocoded one (which would be a different, nearby place).
        await _reverseGeocode(position, emit, token, assignPlaceId: false);
      },
    );
  }

  void _onPredictionsCleared(
    LocationPickerPredictionsCleared event,
    Emitter<LocationPickerState> emit,
  ) {
    emit(state.copyWith(clearPredictions: true));
  }

  /// Checks (never requests) location permission and, if the bloc is still
  /// open, feeds the result back in through [LocationPickerPermissionChecked]
  /// — added as an event rather than emitted directly so it stays safe to
  /// call from a detached/unawaited context.
  Future<void> _checkPermission() async {
    final useCase = _checkLocationPermissionUseCase;
    if (useCase == null) return;

    appLogger.d('[LocationPickerBloc] permission check: requested');
    final result = await useCase(const NoParams()).run();
    if (isClosed) return;

    result.fold(
      (failure) => appLogger.w(
        '[LocationPickerBloc] permission check failed: ${failure.message}',
      ),
      (status) {
        appLogger.d('[LocationPickerBloc] permission check: result=$status');
        add(LocationPickerPermissionChecked(status));
      },
    );
  }

  void _onPermissionChecked(
    LocationPickerPermissionChecked event,
    Emitter<LocationPickerState> emit,
  ) {
    emit(
      state.copyWith(
        hasLocationPermission: event.status == LocationPermissionStatus.granted,
      ),
    );
  }

  /// Owns the full "use my current location" sequence. Requests permission +
  /// resolves the device position (the use case folds in the permission and
  /// location-service checks), validates the result against the supported
  /// area, then moves the camera and reverse-geocodes — all inside one state
  /// transition so:
  ///  - repeated taps are dropped while a request is in flight ([isLocating]),
  ///  - a failed attempt NEVER clobbers a valid selection (the failure lands
  ///    in [currentLocationFailure], not [status]/[position]/[address]),
  ///  - an out-of-country position is reported, never clamped to a bogus
  ///    corner coordinate that then reverse-geocodes open water (SAN-778).
  Future<void> _onCurrentLocationRequested(
    LocationPickerCurrentLocationRequested event,
    Emitter<LocationPickerState> emit,
  ) async {
    final useCase = _getCurrentLocationUseCase;
    if (useCase == null) return;
    // Drop duplicate taps while a request is already running.
    if (state.isLocating) return;

    emit(state.copyWith(isLocating: true, clearCurrentLocationFailure: true));

    final result = await useCase(const NoParams()).run();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        // Non-destructive: keep any existing selection; surface the failure
        // through the dedicated transient channel only.
        emit(
          state.copyWith(
            isLocating: false,
            currentLocationFailure: failure,
            hasLocationPermission:
                !_deniesPermission(failure.code) && state.hasLocationPermission,
          ),
        );
      },
      (position) async {
        if (!_isWithinSupportedArea(position)) {
          emit(
            state.copyWith(
              isLocating: false,
              currentLocationFailure: const LocationFailure(
                message: 'Current location is outside the supported area.',
                code: LocationFailureCodes.outsideSupportedCountry,
              ),
            ),
          );
          return;
        }

        // Supersede any in-flight drag/search geocode with this position.
        final token = _geocodeOp.begin();
        emit(
          state.copyWith(
            isLocating: false,
            status: LocationPickerStatus.geocoding,
            position: position,
            cameraSource: LocationPickerCameraSource.programmatic,
            hasLocationPermission: true,
            clearFailure: true,
            clearPredictions: true,
            clearSelectedPlaceId: true,
            clearCurrentLocationFailure: true,
          ),
        );
        await _reverseGeocode(position, emit, token);
      },
    );
  }

  /// Retries reverse-geocoding for the current pin after an address lookup
  /// failed. Keeps the (valid) coordinate and just re-resolves the address.
  Future<void> _onRetryGeocode(
    LocationPickerRetryGeocode event,
    Emitter<LocationPickerState> emit,
  ) async {
    final position = state.position;
    if (position == null) return;
    final token = _geocodeOp.begin();
    emit(
      state.copyWith(
        status: LocationPickerStatus.geocoding,
        clearFailure: true,
      ),
    );
    await _reverseGeocode(position, emit, token);
  }

  /// App returned to the foreground (e.g. back from Settings). Re-reads the
  /// OS permission state and clears a stale current-location failure so the
  /// user recovers without a restart or an arbitrary delay — deterministic,
  /// never a polling loop or `Future.delayed` (SAN-778).
  void _onResumed(
    LocationPickerResumed event,
    Emitter<LocationPickerState> emit,
  ) {
    if (state.isLocating) return;
    if (state.currentLocationFailure != null) {
      emit(state.copyWith(clearCurrentLocationFailure: true));
    }
    unawaited(_checkPermission());
  }

  static bool _deniesPermission(String? code) =>
      code == LocationFailureCodes.permissionDenied ||
      code == LocationFailureCodes.permissionPermanentlyDenied ||
      code == LocationFailureCodes.serviceDisabled;

  bool _isWithinSupportedArea(LatLng point) {
    final sw = _supportedBounds.southwest;
    final ne = _supportedBounds.northeast;
    return point.latitude >= sw.latitude &&
        point.latitude <= ne.latitude &&
        point.longitude >= sw.longitude &&
        point.longitude <= ne.longitude;
  }

  /// Reverse-geocodes [position] to an address, and — when [assignPlaceId] is
  /// true and a Google resolver is available — a real Google `place_id` too,
  /// so a map-dragged / current-location point becomes a complete, confirmable
  /// selection without a search result. When [assignPlaceId] is false (a
  /// prediction was chosen), the existing search Place ID is preserved and
  /// only the address is resolved.
  Future<void> _reverseGeocode(
    LatLng position,
    Emitter<LocationPickerState> emit,
    int token, {
    bool assignPlaceId = true,
  }) async {
    final placeUseCase = _reverseGeocodePlaceUseCase;
    if (assignPlaceId && placeUseCase != null) {
      final result = await placeUseCase(
        ReverseGeocodePlaceParams(
          position: position,
          localeIdentifier: _localeIdentifier,
        ),
      ).run();
      if (!_geocodeOp.isCurrent(token)) return;

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: LocationPickerStatus.failure,
            failure: failure,
          ),
        ),
        (place) {
          if (place == null || place.placeId == null) {
            // Google has no place for this coordinate: keep the pin, but the
            // selection is NOT complete (no Place ID) — surface an address
            // failure so Confirm stays disabled with a retry, never a bogus
            // Place ID (SAN-778 follow-up).
            emit(
              state.copyWith(
                status: LocationPickerStatus.failure,
                failure: const LocationFailure(
                  message: 'No place found for the selected coordinate.',
                  code: LocationFailureCodes.geocodingFailed,
                ),
              ),
            );
            return;
          }
          emit(
            state.copyWith(
              status: LocationPickerStatus.ready,
              position: position,
              address: place.formattedAddress,
              isoCountryCode: () => place.isoCountryCode,
              selectedPlaceId: () => place.placeId,
              clearFailure: true,
            ),
          );
        },
      );
      return;
    }

    // Platform geocoder path: resolves an address only (no Place ID). Used for
    // the prediction flow (Place ID already known) and non-Google providers.
    final result = await _reverseGeocodeUseCase(
      ReverseGeocodeParams(
        position: position,
        localeIdentifier: _localeIdentifier,
      ),
    ).run();
    if (!_geocodeOp.isCurrent(token)) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LocationPickerStatus.failure,
          failure: failure,
        ),
      ),
      (geocoded) => emit(
        state.copyWith(
          status: LocationPickerStatus.ready,
          position: position,
          address: geocoded.formattedAddress,
          isoCountryCode: () => geocoded.isoCountryCode,
          clearFailure: true,
        ),
      ),
    );
  }
}
