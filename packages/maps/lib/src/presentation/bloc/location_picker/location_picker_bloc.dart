import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/domain/usecases/forward_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/domain/usecases/get_place_details_usecase.dart';
import 'package:maps/src/domain/usecases/open_location_settings_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/search_places_usecase.dart';
import 'package:maps/src/presentation/models/place_search_status.dart';
import 'package:maps/src/services/location_failure_codes.dart';

part 'location_picker_event.dart';
part 'location_picker_state.dart';

class LocationPickerBloc
    extends Bloc<LocationPickerEvent, LocationPickerState> {
  LocationPickerBloc({
    required GetCurrentLocationUseCase getCurrentLocationUseCase,
    required ReverseGeocodeUseCase reverseGeocodeUseCase,
    required ForwardGeocodeUseCase forwardGeocodeUseCase,
    required OpenLocationSettingsUseCase openLocationSettingsUseCase,
    SearchPlacesUseCase? searchPlacesUseCase,
    GetPlaceDetailsUseCase? getPlaceDetailsUseCase,
  })  : _getCurrentLocationUseCase = getCurrentLocationUseCase,
        _reverseGeocodeUseCase = reverseGeocodeUseCase,
        _forwardGeocodeUseCase = forwardGeocodeUseCase,
        _openLocationSettingsUseCase = openLocationSettingsUseCase,
        _searchPlacesUseCase = searchPlacesUseCase,
        _getPlaceDetailsUseCase = getPlaceDetailsUseCase,
        super(const LocationPickerState()) {
    on<LocationPickerStarted>(_onStarted);
    on<LocationPickerCameraIdle>(_onCameraIdle);
    on<LocationPickerSearchSubmitted>(_onSearchSubmitted);
    on<LocationPickerSettingsRequested>(_onSettingsRequested);
    on<LocationPickerQueryChanged>(_onQueryChanged);
    on<LocationPickerPredictionSelected>(_onPredictionSelected);
    on<LocationPickerPredictionsCleared>(_onPredictionsCleared);
  }

  final GetCurrentLocationUseCase _getCurrentLocationUseCase;
  final ReverseGeocodeUseCase _reverseGeocodeUseCase;
  final ForwardGeocodeUseCase _forwardGeocodeUseCase;
  final OpenLocationSettingsUseCase _openLocationSettingsUseCase;
  final SearchPlacesUseCase? _searchPlacesUseCase;
  final GetPlaceDetailsUseCase? _getPlaceDetailsUseCase;

  String? _localeIdentifier;

  int _geocodeOpId = 0;
  int _placesOpId = 0;

  Future<void> _onStarted(
    LocationPickerStarted event,
    Emitter<LocationPickerState> emit,
  ) async {
    _localeIdentifier = event.localeIdentifier;
    final opId = ++_geocodeOpId;

    if (event.initialPosition != null) {
      final hasAddress =
          event.initialAddress != null && event.initialAddress!.isNotEmpty;
      emit(
        state.copyWith(
          status: hasAddress
              ? LocationPickerStatus.ready
              : LocationPickerStatus.geocoding,
          position: event.initialPosition,
          address: event.initialAddress,
          cameraSource: LocationPickerCameraSource.programmatic,
          clearFailure: true,
        ),
      );
      if (!hasAddress) {
        await _reverseGeocode(event.initialPosition!, emit, opId);
      }
      return;
    }

    emit(
      state.copyWith(
        status: LocationPickerStatus.loadingLocation,
        clearFailure: true,
      ),
    );

    final result = await _getCurrentLocationUseCase(const NoParams()).run();
    if (_geocodeOpId != opId) return;

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: _statusFromFailure(failure),
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
        await _reverseGeocode(position, emit, opId);
      },
    );
  }

  Future<void> _onCameraIdle(
    LocationPickerCameraIdle event,
    Emitter<LocationPickerState> emit,
  ) async {
    if (state.status == LocationPickerStatus.loadingLocation) return;
    if (state.position == event.position) return;

    final opId = ++_geocodeOpId;
    emit(
      state.copyWith(
        status: LocationPickerStatus.geocoding,
        position: event.position,
        cameraSource: LocationPickerCameraSource.user,
        clearFailure: true,
        clearPredictions: true,
      ),
    );

    await _reverseGeocode(event.position, emit, opId);
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
    if (_searchPlacesUseCase != null && state.hasPredictions) return;

    await _submitViaGeocode(query, emit);
  }

  Future<void> _submitViaGeocode(
    String query,
    Emitter<LocationPickerState> emit,
  ) async {
    final opId = ++_geocodeOpId;
    ++_placesOpId;
    emit(
      state.copyWith(
        status: LocationPickerStatus.geocoding,
        clearFailure: true,
        clearPredictions: true,
      ),
    );

    final result = await _forwardGeocodeUseCase(
      ForwardGeocodeParams(
        address: query,
        localeIdentifier: _localeIdentifier,
      ),
    ).run();
    if (_geocodeOpId != opId) return;

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
        await _reverseGeocode(position, emit, opId);
      },
    );
  }

  Future<void> _onSettingsRequested(
    LocationPickerSettingsRequested event,
    Emitter<LocationPickerState> emit,
  ) async {
    await _openLocationSettingsUseCase(const NoParams()).run();
  }

  Future<void> _onQueryChanged(
    LocationPickerQueryChanged event,
    Emitter<LocationPickerState> emit,
  ) async {
    final useCase = _searchPlacesUseCase;
    if (useCase == null) return;

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

    final opId = ++_placesOpId;
    emit(
      state.copyWith(
        searchStatus: PlaceSearchStatus.searching,
        searchQuery: query,
        clearSearchError: true,
      ),
    );

    final result = await useCase(
      SearchPlacesParams(
        query: query,
        language: _localeIdentifier,
        biasLocation: state.position,
      ),
    ).run();
    if (_placesOpId != opId) return;

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

    final opId = ++_geocodeOpId;
    ++_placesOpId;
    emit(
      state.copyWith(
        status: LocationPickerStatus.geocoding,
        clearPredictions: true,
        clearFailure: true,
      ),
    );

    final result = await useCase(
      GetPlaceDetailsParams(placeId: event.prediction.placeId),
    ).run();
    if (_geocodeOpId != opId) return;

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
        await _reverseGeocode(position, emit, opId);
      },
    );
  }

  void _onPredictionsCleared(
    LocationPickerPredictionsCleared event,
    Emitter<LocationPickerState> emit,
  ) {
    emit(state.copyWith(clearPredictions: true));
  }

  Future<void> _reverseGeocode(
    LatLng position,
    Emitter<LocationPickerState> emit,
    int opId,
  ) async {
    final result = await _reverseGeocodeUseCase(
      ReverseGeocodeParams(
        position: position,
        localeIdentifier: _localeIdentifier,
      ),
    ).run();
    if (_geocodeOpId != opId) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LocationPickerStatus.failure,
          failure: failure,
        ),
      ),
      (address) => emit(
        state.copyWith(
          status: LocationPickerStatus.ready,
          position: position,
          address: address,
          clearFailure: true,
        ),
      ),
    );
  }

  LocationPickerStatus _statusFromFailure(Failure failure) {
    return switch (failure.code) {
      LocationFailureCodes.permissionDenied =>
        LocationPickerStatus.permissionDenied,
      LocationFailureCodes.permissionPermanentlyDenied =>
        LocationPickerStatus.permissionPermanentlyDenied,
      LocationFailureCodes.serviceDisabled =>
        LocationPickerStatus.serviceDisabled,
      _ => LocationPickerStatus.failure,
    };
  }
}
