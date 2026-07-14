import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/domain/usecases/forward_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/domain/usecases/get_place_details_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/search_places_usecase.dart';
import 'package:maps/src/presentation/models/place_search_status.dart';

part 'coverage_area_event.dart';
part 'coverage_area_state.dart';

class CoverageAreaBloc extends Bloc<CoverageAreaEvent, CoverageAreaState> {
  CoverageAreaBloc({
    required GetCurrentLocationUseCase getCurrentLocationUseCase,
    required ReverseGeocodeUseCase reverseGeocodeUseCase,
    required ForwardGeocodeUseCase forwardGeocodeUseCase,
    SearchPlacesUseCase? searchPlacesUseCase,
    GetPlaceDetailsUseCase? getPlaceDetailsUseCase,
  })  : _getCurrentLocationUseCase = getCurrentLocationUseCase,
        _reverseGeocodeUseCase = reverseGeocodeUseCase,
        _forwardGeocodeUseCase = forwardGeocodeUseCase,
        _searchPlacesUseCase = searchPlacesUseCase,
        _getPlaceDetailsUseCase = getPlaceDetailsUseCase,
        super(const CoverageAreaState()) {
    on<CoverageAreaStarted>(_onStarted);
    on<CoverageAreaLocationUpdated>(_onLocationUpdated);
    on<CoverageAreaCameraIdle>(_onCameraIdle);
    on<CoverageAreaSearchSubmitted>(_onSearchSubmitted);
    on<CoverageAreaRadiusChanged>(_onRadiusChanged);
    on<CoverageAreaServingAreaAdded>(_onServingAreaAdded);
    on<CoverageAreaServingAreaRemoved>(_onServingAreaRemoved);
    on<CoverageAreaQueryChanged>(_onQueryChanged);
    on<CoverageAreaPredictionSelected>(_onPredictionSelected);
    on<CoverageAreaPredictionsCleared>(_onPredictionsCleared);
  }

  final GetCurrentLocationUseCase _getCurrentLocationUseCase;
  final ReverseGeocodeUseCase _reverseGeocodeUseCase;
  final ForwardGeocodeUseCase _forwardGeocodeUseCase;
  final SearchPlacesUseCase? _searchPlacesUseCase;
  final GetPlaceDetailsUseCase? _getPlaceDetailsUseCase;

  String? _localeIdentifier;

  int _locationOpId = 0;

  int _searchOpId = 0;

  Future<void> _onStarted(
    CoverageAreaStarted event,
    Emitter<CoverageAreaState> emit,
  ) async {
    _localeIdentifier = event.localeIdentifier;
    final opId = ++_locationOpId;
    emit(
      state.copyWith(
        status: CoverageAreaStatus.loading,
        servingAreas: event.initialServingAreas,
        clearFailure: true,
      ),
    );

    if (event.initialPosition != null) {
      await _applyLocation(
        opId: opId,
        position: event.initialPosition!,
        address: event.initialAddress,
        radiusKm: event.initialRadiusKm ?? state.radiusKm,
        emit: emit,
        cameraSource: CoverageAreaCameraSource.programmatic,
      );
      return;
    }

    final result = await _getCurrentLocationUseCase(const NoParams()).run();
    if (_locationOpId != opId) return;
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: CoverageAreaStatus.failure,
            failure: failure,
          ),
        );
      },
      (position) async {
        await _applyLocation(
          opId: opId,
          position: position,
          radiusKm: state.radiusKm,
          emit: emit,
          cameraSource: CoverageAreaCameraSource.programmatic,
        );
      },
    );
  }

  Future<void> _onLocationUpdated(
    CoverageAreaLocationUpdated event,
    Emitter<CoverageAreaState> emit,
  ) async {
    await _applyLocation(
      opId: ++_locationOpId,
      position: event.position,
      address: event.address,
      radiusKm: state.radiusKm,
      emit: emit,
      cameraSource: CoverageAreaCameraSource.programmatic,
    );
  }

  Future<void> _onCameraIdle(
    CoverageAreaCameraIdle event,
    Emitter<CoverageAreaState> emit,
  ) async {
    await _applyLocation(
      opId: ++_locationOpId,
      position: event.position,
      radiusKm: state.radiusKm,
      emit: emit,
      cameraSource: CoverageAreaCameraSource.none,
    );
  }

  Future<void> _onSearchSubmitted(
    CoverageAreaSearchSubmitted event,
    Emitter<CoverageAreaState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    final opId = ++_locationOpId;
    emit(
      state.copyWith(
        status: CoverageAreaStatus.loading,
        clearFailure: true,
      ),
    );

    final result = await _forwardGeocodeUseCase(
      ForwardGeocodeParams(
        address: query,
        localeIdentifier: _localeIdentifier,
      ),
    ).run();
    if (_locationOpId != opId) return;

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: CoverageAreaStatus.failure,
            failure: failure,
          ),
        );
      },
      (position) async {
        await _applyLocation(
          opId: opId,
          position: position,
          radiusKm: state.radiusKm,
          emit: emit,
          cameraSource: CoverageAreaCameraSource.programmatic,
        );
      },
    );
  }

  void _onRadiusChanged(
    CoverageAreaRadiusChanged event,
    Emitter<CoverageAreaState> emit,
  ) {
    emit(state.copyWith(radiusKm: event.radiusKm));
  }

  void _onServingAreaAdded(
    CoverageAreaServingAreaAdded event,
    Emitter<CoverageAreaState> emit,
  ) {
    final exists =
        state.servingAreas.any((a) => a.placeId == event.area.placeId);
    if (exists) return;
    emit(
      state.copyWith(
        servingAreas: [...state.servingAreas, event.area],
      ),
    );
  }

  void _onServingAreaRemoved(
    CoverageAreaServingAreaRemoved event,
    Emitter<CoverageAreaState> emit,
  ) {
    emit(
      state.copyWith(
        servingAreas: state.servingAreas
            .where((a) => a.placeId != event.placeId)
            .toList(growable: false),
      ),
    );
  }

  Future<void> _onQueryChanged(
    CoverageAreaQueryChanged event,
    Emitter<CoverageAreaState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(
        state.copyWith(
          predictions: const [],
          searchStatus: PlaceSearchStatus.idle,
          searchQuery: '',
          clearSearchError: true,
        ),
      );
      return;
    }

    final searchUseCase = _searchPlacesUseCase;
    if (searchUseCase == null) return;

    final opId = ++_searchOpId;
    emit(
      state.copyWith(
        searchStatus: PlaceSearchStatus.searching,
        searchQuery: query,
        clearSearchError: true,
      ),
    );

    final result = await searchUseCase(
      SearchPlacesParams(
        query: query,
        language: _localeIdentifier,
        biasLocation: state.position,
      ),
    ).run();
    if (_searchOpId != opId) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          searchStatus: PlaceSearchStatus.failure,
          searchError: failure.message,
          predictions: const [],
        ),
      ),
      (predictions) => emit(
        state.copyWith(
          searchStatus: predictions.isEmpty
              ? PlaceSearchStatus.empty
              : PlaceSearchStatus.success,
          predictions: predictions,
        ),
      ),
    );
  }

  Future<void> _onPredictionSelected(
    CoverageAreaPredictionSelected event,
    Emitter<CoverageAreaState> emit,
  ) async {
    final prediction = event.prediction;
    final detailsUseCase = _getPlaceDetailsUseCase;

    emit(
      state.copyWith(
        predictions: const [],
        searchStatus: PlaceSearchStatus.idle,
        searchQuery: '',
      ),
    );

    LatLng latLng;
    if (detailsUseCase != null) {
      final result = await detailsUseCase(
        GetPlaceDetailsParams(placeId: prediction.placeId),
      ).run();
      final resolved = result.getOrElse(
        (_) => state.position ?? const LatLng(0, 0),
      );
      latLng = resolved;
    } else {
      latLng = state.position ?? const LatLng(0, 0);
    }

    final area = ServingArea(
      placeId: prediction.placeId,
      name: prediction.mainText,
      address: prediction.secondaryText,
      latLng: latLng,
    );

    add(CoverageAreaServingAreaAdded(area));
  }

  void _onPredictionsCleared(
    CoverageAreaPredictionsCleared event,
    Emitter<CoverageAreaState> emit,
  ) {
    emit(
      state.copyWith(
        predictions: const [],
        searchStatus: PlaceSearchStatus.idle,
        searchQuery: '',
        clearSearchError: true,
      ),
    );
  }

  Future<void> _applyLocation({
    required int opId,
    required LatLng position,
    required double radiusKm,
    required Emitter<CoverageAreaState> emit,
    required CoverageAreaCameraSource cameraSource,
    String? address,
  }) async {
    final hasAddress = address != null && address.isNotEmpty;

    emit(
      state.copyWith(
        status: CoverageAreaStatus.loading,
        position: position,
        radiusKm: radiusKm,
        cameraSource: cameraSource,
        address: address,
        clearAddress: !hasAddress,
        clearFailure: true,
      ),
    );

    var resolvedAddress = address;
    Failure? addressFailure;
    if (!hasAddress) {
      final addressResult = await _reverseGeocodeUseCase(
        ReverseGeocodeParams(
          position: position,
          localeIdentifier: _localeIdentifier,
        ),
      ).run();
      if (_locationOpId != opId) return;
      resolvedAddress = addressResult.fold(
        (failure) {
          addressFailure = failure;
          return null;
        },
        (value) => value,
      );
    }

    emit(
      state.copyWith(
        status: CoverageAreaStatus.ready,
        address: resolvedAddress,
        clearAddress: resolvedAddress == null,
        position: position,
        radiusKm: radiusKm,
        cameraSource: cameraSource,
        failure: addressFailure,
      ),
    );
  }
}
