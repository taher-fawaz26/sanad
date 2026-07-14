import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/coverage_mode.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/domain/usecases/coverage_location_intent.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/domain/usecases/resolve_coverage_location_usecase.dart';
import 'package:maps/src/presentation/controllers/serving_area_controller.dart';

part 'coverage_area_event.dart';
part 'coverage_area_state.dart';

class CoverageAreaBloc extends Bloc<CoverageAreaEvent, CoverageAreaState> {
  CoverageAreaBloc({
    required ResolveCoverageLocationUseCase resolveCoverageLocationUseCase,
    required GetCurrentLocationUseCase getCurrentLocationUseCase,
  })  : _resolveCoverageLocationUseCase = resolveCoverageLocationUseCase,
        _getCurrentLocationUseCase = getCurrentLocationUseCase,
        _autoAreasController = ServingAreaController<String>(),
        super(const CoverageAreaState()) {
    on<CoverageAreaStarted>(_onStarted);
    on<CoverageAreaMapMoved>(_onMapMoved);
    on<CoverageAreaCurrentLocationRequested>(_onCurrentLocationRequested);
    on<CoverageAreaRadiusChanged>(_onRadiusChanged);
    on<CoverageAreaAutoAreaRemoved>(_onAutoAreaRemoved);
    on<CoverageAreaExtraAreaSet>(_onExtraAreaSet);
    on<CoverageAreaExtraAreaRemoved>(_onExtraAreaRemoved);
  }

  final ResolveCoverageLocationUseCase _resolveCoverageLocationUseCase;
  final GetCurrentLocationUseCase _getCurrentLocationUseCase;
  final ServingAreaController<String> _autoAreasController;

  String? _localeIdentifier;
  String? _branchId;
  int _locationOpId = 0;

  ServingAreaController<String> get autoAreasController => _autoAreasController;

  Future<void> _onStarted(
    CoverageAreaStarted event,
    Emitter<CoverageAreaState> emit,
  ) async {
    _localeIdentifier = event.localeIdentifier;
    _branchId = event.branchId;

    emit(
      state.copyWith(
        status: CoverageAreaStatus.loading,
        mode: event.mode,
        radiusKm: event.initialRadiusKm ?? state.radiusKm,
        extraArea: event.initialExtraArea,
        clearFailure: true,
      ),
    );

    if (event.initialCenter != null) {
      await _resolveLocation(
        center: event.initialCenter!,
        emit: emit,
        radiusKm: event.initialRadiusKm,
        cameraSource: CoverageAreaCameraSource.programmatic,
        elevateMode: false,
      );
      return;
    }

    await _requestCurrentLocation(emit);
  }

  Future<void> _onMapMoved(
    CoverageAreaMapMoved event,
    Emitter<CoverageAreaState> emit,
  ) async {
    if (state.center == event.center) return;

    await _resolveLocation(
      center: event.center,
      emit: emit,
      cameraSource: event.cameraSource,
      elevateMode: true,
    );
  }

  Future<void> _onCurrentLocationRequested(
    CoverageAreaCurrentLocationRequested event,
    Emitter<CoverageAreaState> emit,
  ) async {
    await _requestCurrentLocation(emit);
  }

  Future<void> _onRadiusChanged(
    CoverageAreaRadiusChanged event,
    Emitter<CoverageAreaState> emit,
  ) async {
    final center = state.center;
    if (center == null) {
      emit(state.copyWith(radiusKm: event.radiusKm));
      return;
    }

    await _resolveLocation(
      center: center,
      emit: emit,
      radiusKm: event.radiusKm,
      elevateMode: true,
    );
  }

  void _onAutoAreaRemoved(
    CoverageAreaAutoAreaRemoved event,
    Emitter<CoverageAreaState> emit,
  ) {
    _autoAreasController.remove(event.name);
    emit(state.copyWith(autoAreas: _autoAreasController.items));
  }

  void _onExtraAreaSet(
    CoverageAreaExtraAreaSet event,
    Emitter<CoverageAreaState> emit,
  ) {
    emit(state.copyWith(extraArea: event.area));
  }

  void _onExtraAreaRemoved(
    CoverageAreaExtraAreaRemoved event,
    Emitter<CoverageAreaState> emit,
  ) {
    emit(state.copyWith(clearExtraArea: true));
  }

  Future<void> _requestCurrentLocation(Emitter<CoverageAreaState> emit) async {
    final opId = ++_locationOpId;
    emit(
      state.copyWith(
        status: CoverageAreaStatus.loading,
        clearFailure: true,
      ),
    );

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
        await _resolveLocation(
          center: position,
          emit: emit,
          cameraSource: CoverageAreaCameraSource.programmatic,
          elevateMode: true,
          opId: opId,
        );
      },
    );
  }

  Future<void> _resolveLocation({
    required LatLng center,
    required Emitter<CoverageAreaState> emit,
    required bool elevateMode,
    double? radiusKm,
    CoverageAreaCameraSource cameraSource = CoverageAreaCameraSource.none,
    int? opId,
  }) async {
    final resolvedOpId = opId ?? ++_locationOpId;
    final resolvedRadius = radiusKm ?? state.radiusKm;
    final effectiveMode = _effectiveMode(elevateMode: elevateMode);

    emit(
      state.copyWith(
        status: CoverageAreaStatus.loading,
        center: center,
        radiusKm: resolvedRadius,
        cameraSource: cameraSource,
        clearFailure: true,
      ),
    );

    final intent = _buildIntent(
      center: center,
      radiusKm: resolvedRadius,
      mode: effectiveMode,
    );

    final result = await _resolveCoverageLocationUseCase(intent).run();
    if (_locationOpId != resolvedOpId) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: CoverageAreaStatus.failure,
            failure: failure,
          ),
        );
      },
      (location) {
        _autoAreasController.replace(location.nearbyAreas);
        emit(
          state.copyWith(
            status: CoverageAreaStatus.ready,
            center: location.center,
            address: location.address,
            radiusKm: resolvedRadius,
            mode: effectiveMode,
            autoAreas: _autoAreasController.items,
            cameraSource: cameraSource,
          ),
        );
      },
    );
  }

  CoverageMode _effectiveMode({required bool elevateMode}) {
    if (elevateMode && state.mode == CoverageMode.edit) {
      return CoverageMode.recalculate;
    }
    return state.mode;
  }

  CoverageLocationIntent _buildIntent({
    required LatLng center,
    required double radiusKm,
    required CoverageMode mode,
  }) {
    return switch (mode) {
      CoverageMode.create => CreateCoverageIntent(
          center: center,
          radiusKm: radiusKm,
          localeIdentifier: _localeIdentifier,
        ),
      CoverageMode.edit => EditCoverageIntent(
          branchId: _branchId!,
          center: center,
          radiusKm: radiusKm,
          localeIdentifier: _localeIdentifier,
        ),
      CoverageMode.recalculate => RecalculateCoverageIntent(
          branchId: _branchId!,
          center: center,
          radiusKm: radiusKm,
          localeIdentifier: _localeIdentifier,
        ),
    };
  }

  @override
  Future<void> close() {
    _autoAreasController.dispose();
    return super.close();
  }
}
