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
        _searchPlacesUseCase = searchPlacesUseCase,
        _getPlaceDetailsUseCase = getPlaceDetailsUseCase,
        super(const MapAreaPickerState()) {
    on<MapAreaPickerStarted>(_onStarted);
    on<MapAreaPickerLocationChanged>(_onLocationChanged);
    on<MapAreaPickerQueryChanged>(_onQueryChanged);
    on<MapAreaPickerPredictionSelected>(_onPredictionSelected);
    on<MapAreaPickerPredictionsCleared>(_onPredictionsCleared);
    on<MapAreaPickerConfirmed>(_onConfirmed);
  }

  final ReverseGeocodeUseCase _reverseGeocodeUseCase;
  final SearchPlacesUseCase? _searchPlacesUseCase;
  final GetPlaceDetailsUseCase? _getPlaceDetailsUseCase;

  String? _localeIdentifier;

  int _geocodeOpId = 0;
  int _placesOpId = 0;
  int _detailsOpId = 0;

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
        final opId = ++_geocodeOpId;
        await _reverseGeocode(event.initialPosition!, emit, opId);
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

    final opId = ++_geocodeOpId;
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

    await _reverseGeocode(event.position, emit, opId);
  }

  Future<void> _onQueryChanged(
    MapAreaPickerQueryChanged event,
    Emitter<MapAreaPickerState> emit,
  ) async {
    final useCase = _searchPlacesUseCase;
    if (useCase == null) return;

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
    MapAreaPickerPredictionSelected event,
    Emitter<MapAreaPickerState> emit,
  ) async {
    final useCase = _getPlaceDetailsUseCase;
    if (useCase == null) return;

    final prediction = event.prediction;
    final opId = ++_detailsOpId;
    ++_placesOpId;

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
    if (_detailsOpId != opId) return;

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
          title: state.selectedTitle ?? address,
          address: address,
          position: position,
        ),
      ),
    );
  }

  Future<void> _reverseGeocode(
    LatLng position,
    Emitter<MapAreaPickerState> emit,
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
          status: MapAreaPickerStatus.failure,
          failure: failure,
        ),
      ),
      (address) => emit(
        state.copyWith(
          status: MapAreaPickerStatus.ready,
          position: position,
          address: address,
          clearFailure: true,
        ),
      ),
    );
  }
}
