import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/map_area_picker_result.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/domain/usecases/get_place_details_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/search_places_usecase.dart';
import 'package:maps/src/presentation/models/place_search_status.dart';
import 'package:maps/src/presentation/utils/latest_operation.dart';
import 'package:maps/src/presentation/utils/place_search_runner.dart';

part 'map_area_picker_event.dart';
part 'map_area_picker_state.dart';

/// Dedicated bloc for the map area picker widget.
class MapAreaPickerBloc
    extends Bloc<MapAreaPickerEvent, MapAreaPickerState> {
  MapAreaPickerBloc({
    required ReverseGeocodeUseCase reverseGeocodeUseCase,
    SearchPlacesUseCase? searchPlacesUseCase,
    GetPlaceDetailsUseCase? getPlaceDetailsUseCase,
  })  : _reverseGeocodeUseCase = reverseGeocodeUseCase,
        _getPlaceDetailsUseCase = getPlaceDetailsUseCase,
        _searchRunner =
            PlaceSearchRunner(searchPlacesUseCase: searchPlacesUseCase),
        super(const MapAreaPickerState()) {
    on<MapAreaPickerStarted>(_onStarted);
    on<MapAreaPickerLocationChanged>(_onLocationChanged);
    on<MapAreaPickerQueryChanged>(_onQueryChanged);
    on<MapAreaPickerPredictionSelected>(_onPredictionSelected);
    on<MapAreaPickerPredictionsCleared>(_onPredictionsCleared);
    on<MapAreaPickerConfirmed>(_onConfirmed);
  }

  final ReverseGeocodeUseCase _reverseGeocodeUseCase;
  final GetPlaceDetailsUseCase? _getPlaceDetailsUseCase;
  final PlaceSearchRunner _searchRunner;

  String? _localeIdentifier;

  final LatestOperation _geocodeOp = LatestOperation();
  final LatestOperation _detailsOp = LatestOperation();

  Future<void> _onStarted(
    MapAreaPickerStarted event,
    Emitter<MapAreaPickerState> emit,
  ) async {
    _localeIdentifier = event.localeIdentifier;

    if (event.initialPosition != null) {
      final hasAddress =
          event.initialAddress != null && event.initialAddress!.isNotEmpty;
      emit(
        state.copyWith(
          status: hasAddress
              ? MapAreaPickerStatus.ready
              : MapAreaPickerStatus.geocoding,
          position: event.initialPosition,
          address: event.initialAddress,
          cameraSource: MapAreaPickerCameraSource.programmatic,
          clearFailure: true,
        ),
      );
      if (!hasAddress) {
        final token = _geocodeOp.begin();
        await _reverseGeocode(event.initialPosition!, emit, token);
      }
      return;
    }

    emit(
      state.copyWith(
        status: MapAreaPickerStatus.ready,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onLocationChanged(
    MapAreaPickerLocationChanged event,
    Emitter<MapAreaPickerState> emit,
  ) async {
    if (state.position == event.position) return;

    final token = _geocodeOp.begin();
    final clearPlace = event.cameraSource == MapAreaPickerCameraSource.user;

    emit(
      state.copyWith(
        status: MapAreaPickerStatus.geocoding,
        position: event.position,
        cameraSource: event.cameraSource,
        clearFailure: true,
        clearPredictions: true,
        clearSelectedPlace: clearPlace,
      ),
    );

    await _reverseGeocode(event.position, emit, token);
  }

  Future<void> _onQueryChanged(
    MapAreaPickerQueryChanged event,
    Emitter<MapAreaPickerState> emit,
  ) async {
    if (!_searchRunner.isEnabled) return;

    final query = event.query.trim();
    if (query.length < 2) {
      emit(
        state.copyWith(
          clearPredictions: true,
          clearSearchError: true,
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
    MapAreaPickerPredictionSelected event,
    Emitter<MapAreaPickerState> emit,
  ) async {
    final useCase = _getPlaceDetailsUseCase;
    if (useCase == null) return;

    final prediction = event.prediction;
    final token = _detailsOp.begin();
    _searchRunner.cancelPending();

    emit(
      state.copyWith(
        status: MapAreaPickerStatus.geocoding,
        clearPredictions: true,
        clearFailure: true,
        selectedPlaceId: prediction.placeId,
        selectedTitle: prediction.mainText,
      ),
    );

    final result = await useCase(
      GetPlaceDetailsParams(placeId: prediction.placeId),
    ).run();
    if (!_detailsOp.isCurrent(token)) return;

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: MapAreaPickerStatus.failure,
            failure: failure,
            clearSelectedPlace: true,
          ),
        );
      },
      (position) async {
        add(
          MapAreaPickerLocationChanged(
            position,
            cameraSource: MapAreaPickerCameraSource.programmatic,
          ),
        );
      },
    );
  }

  void _onPredictionsCleared(
    MapAreaPickerPredictionsCleared event,
    Emitter<MapAreaPickerState> emit,
  ) {
    emit(state.copyWith(clearPredictions: true));
  }

  void _onConfirmed(
    MapAreaPickerConfirmed event,
    Emitter<MapAreaPickerState> emit,
  ) {
    final position = state.position;
    final address = state.address;
    if (position == null || address == null || address.isEmpty) return;

    emit(
      state.copyWith(
        pickedResult: MapAreaPickerResult(
          placeId: state.selectedPlaceId,
          // Prefer the chosen prediction's name, then the reverse-geocoded
          // area name, and only fall back to the full address as a last resort.
          areaName: state.selectedTitle ?? state.resolvedAreaName ?? address,
          address: address,
          position: position,
        ),
      ),
    );
  }

  Future<void> _reverseGeocode(
    LatLng position,
    Emitter<MapAreaPickerState> emit,
    int token,
  ) async {
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
          status: MapAreaPickerStatus.failure,
          failure: failure,
        ),
      ),
      (geocoded) => emit(
        state.copyWith(
          status: MapAreaPickerStatus.ready,
          position: position,
          address: geocoded.formattedAddress,
          resolvedAreaName: geocoded.areaName,
          clearFailure: true,
        ),
      ),
    );
  }
}
