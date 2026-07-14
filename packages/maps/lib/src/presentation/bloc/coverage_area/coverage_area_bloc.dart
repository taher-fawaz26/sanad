import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/usecases/forward_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/domain/usecases/get_nearby_areas_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_usecase.dart';

part 'coverage_area_event.dart';
part 'coverage_area_state.dart';

class CoverageAreaBloc extends Bloc<CoverageAreaEvent, CoverageAreaState> {
  CoverageAreaBloc({
    required GetCurrentLocationUseCase getCurrentLocationUseCase,
    required ReverseGeocodeUseCase reverseGeocodeUseCase,
    required ForwardGeocodeUseCase forwardGeocodeUseCase,
    required GetNearbyAreasUseCase getNearbyAreasUseCase,
  })  : _getCurrentLocationUseCase = getCurrentLocationUseCase,
        _reverseGeocodeUseCase = reverseGeocodeUseCase,
        _forwardGeocodeUseCase = forwardGeocodeUseCase,
        _getNearbyAreasUseCase = getNearbyAreasUseCase,
        super(const CoverageAreaState()) {
    on<CoverageAreaStarted>(_onStarted);
    on<CoverageAreaLocationUpdated>(_onLocationUpdated);
    on<CoverageAreaSearchSubmitted>(_onSearchSubmitted);
    on<CoverageAreaRadiusChanged>(_onRadiusChanged);
    on<CoverageAreaAreaRemoved>(_onAreaRemoved);
    on<CoverageAreaAreaAdded>(_onAreaAdded);
  }

  final GetCurrentLocationUseCase _getCurrentLocationUseCase;
  final ReverseGeocodeUseCase _reverseGeocodeUseCase;
  final ForwardGeocodeUseCase _forwardGeocodeUseCase;
  final GetNearbyAreasUseCase _getNearbyAreasUseCase;

  String? _localeIdentifier;

  int _locationOpId = 0;

  int _areasOpId = 0;

  Future<void> _onStarted(
    CoverageAreaStarted event,
    Emitter<CoverageAreaState> emit,
  ) async {
    _localeIdentifier = event.localeIdentifier;
    final opId = ++_locationOpId;
    emit(
      state.copyWith(
        status: CoverageAreaStatus.loading,
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

  Future<void> _onRadiusChanged(
    CoverageAreaRadiusChanged event,
    Emitter<CoverageAreaState> emit,
  ) async {
    final position = state.position;
    if (position == null) {
      emit(state.copyWith(radiusKm: event.radiusKm));
      return;
    }

    emit(
      state.copyWith(
        radiusKm: event.radiusKm,
        status: CoverageAreaStatus.loading,
      ),
    );
    await _refreshCoveredAreas(
      areasOpId: ++_areasOpId,
      position: position,
      radiusKm: event.radiusKm,
      emit: emit,
    );
  }

  void _onAreaRemoved(
    CoverageAreaAreaRemoved event,
    Emitter<CoverageAreaState> emit,
  ) {
    final area = event.area;
    if (state.suggestedAreas.contains(area)) {
      emit(state.copyWith(removedAreas: {...state.removedAreas, area}));
    } else if (state.customAreas.contains(area)) {
      emit(
        state.copyWith(
          customAreas: state.customAreas
              .where((a) => a != area)
              .toList(growable: false),
        ),
      );
    }
  }

  void _onAreaAdded(
    CoverageAreaAreaAdded event,
    Emitter<CoverageAreaState> emit,
  ) {
    final area = event.area.trim();
    if (area.isEmpty) return;

    if (state.suggestedAreas.contains(area)) {
      if (state.removedAreas.contains(area)) {
        emit(
          state.copyWith(
            removedAreas: {...state.removedAreas}..remove(area),
          ),
        );
      }
      return;
    }

    if (state.customAreas.contains(area)) return;
    emit(state.copyWith(customAreas: [...state.customAreas, area]));
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
        resetAreas: true,
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
        address: resolvedAddress,
        clearAddress: resolvedAddress == null,
        position: position,
        radiusKm: radiusKm,
        cameraSource: cameraSource,
        failure: addressFailure,
      ),
    );

    await _refreshCoveredAreas(
      areasOpId: ++_areasOpId,
      position: position,
      radiusKm: radiusKm,
      emit: emit,
    );
  }

  Future<void> _refreshCoveredAreas({
    required int areasOpId,
    required LatLng position,
    required double radiusKm,
    required Emitter<CoverageAreaState> emit,
  }) async {
    final areasResult = await _getNearbyAreasUseCase(
      NearbyAreasParams(
        center: position,
        radiusKm: radiusKm,
        localeIdentifier: _localeIdentifier,
      ),
    ).run();
    if (_areasOpId != areasOpId) return;

    areasResult.fold(
      (_) => emit(state.copyWith(status: CoverageAreaStatus.ready)),
      (areas) => emit(
        state.copyWith(
          status: CoverageAreaStatus.ready,
          suggestedAreas: areas,
        ),
      ),
    );
  }
}
