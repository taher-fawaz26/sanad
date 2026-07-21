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
import 'package:maps/src/presentation/utils/latest_operation.dart';

part 'coverage_area_event.dart';
part 'coverage_area_state.dart';

class CoverageAreaBloc extends Bloc<CoverageAreaEvent, CoverageAreaState> {
  CoverageAreaBloc({
    required ResolveCoverageLocationUseCase resolveCoverageLocationUseCase,
    required GetCurrentLocationUseCase getCurrentLocationUseCase,
  }) : _resolveCoverageLocationUseCase = resolveCoverageLocationUseCase,
       _getCurrentLocationUseCase = getCurrentLocationUseCase,
       _autoAreasController = ServingAreaController<ServingArea>(),
       _extraAreasController = ServingAreaController<ServingArea>(),
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
  final ServingAreaController<ServingArea> _autoAreasController;
  final ServingAreaController<ServingArea> _extraAreasController;

  /// Auto-area names the user has explicitly removed. Persisted for the life
  /// of the bloc so a subsequent recompute never resurrects them.
  final Set<String> _removedAutoAreaNames = {};

  String? _localeIdentifier;
  String? _cityId;
  final LatestOperation _locationOp = LatestOperation();

  ServingAreaController<ServingArea> get autoAreasController =>
      _autoAreasController;

  Future<void> _onStarted(
    CoverageAreaStarted event,
    Emitter<CoverageAreaState> emit,
  ) async {
    _localeIdentifier = event.localeIdentifier;
    _cityId = event.cityId;

    if (event.initialExtraAreas.isNotEmpty) {
      _extraAreasController.replace(event.initialExtraAreas);
    }

    // Edit mode: show the caller-provided saved areas immediately, without a
    // network resolve. The maps platform does not know how to load them — the
    // feature seeds them via [initialAutoAreas]. The first user interaction
    // elevates the mode to recalculate and refreshes areas from the geocoder.
    if (event.mode == CoverageMode.edit &&
        event.initialCenter != null &&
        event.initialAutoAreas.isNotEmpty) {
      _autoAreasController.replace(event.initialAutoAreas);
      final hasAddress =
          event.initialAddress != null && event.initialAddress!.isNotEmpty;
      emit(
        state.copyWith(
          status: hasAddress
              ? CoverageAreaStatus.ready
              : CoverageAreaStatus.loading,
          mode: event.mode,
          center: event.initialCenter,
          address: event.initialAddress,
          radiusKm: event.initialRadiusKm ?? state.radiusKm,
          autoAreas: _autoAreasController.items,
          extraAreas: _extraAreasController.items,
          cameraSource: CoverageAreaCameraSource.programmatic,
          clearFailure: true,
        ),
      );
      if (hasAddress) return;
      await _resolveLocation(
        center: event.initialCenter!,
        emit: emit,
        radiusKm: event.initialRadiusKm,
        cameraSource: CoverageAreaCameraSource.programmatic,
        elevateMode: true,
      );
      return;
    }

    emit(
      state.copyWith(
        status: CoverageAreaStatus.loading,
        mode: event.mode,
        radiusKm: event.initialRadiusKm ?? state.radiusKm,
        extraAreas: _extraAreasController.items,
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

    // No saved/explicit center: open on the default UAE viewport with no
    // center and WITHOUT requesting location permission. Current location is
    // used only when the user explicitly requests it
    // ([CoverageAreaCurrentLocationRequested]).
    emit(state.copyWith(status: CoverageAreaStatus.ready, clearFailure: true));
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
    _removedAutoAreaNames.add(event.name);
    for (final area
        in _autoAreasController.items
            .where((a) => a.name == event.name)
            .toList(growable: false)) {
      _autoAreasController.remove(area);
    }
    emit(state.copyWith(autoAreas: _autoAreasController.items));
  }

  void _onExtraAreaSet(
    CoverageAreaExtraAreaSet event,
    Emitter<CoverageAreaState> emit,
  ) {
    _extraAreasController.add(event.area);
    emit(state.copyWith(extraAreas: _extraAreasController.items));
  }

  void _onExtraAreaRemoved(
    CoverageAreaExtraAreaRemoved event,
    Emitter<CoverageAreaState> emit,
  ) {
    _extraAreasController.remove(event.area);
    emit(state.copyWith(extraAreas: _extraAreasController.items));
  }

  Future<void> _requestCurrentLocation(Emitter<CoverageAreaState> emit) async {
    final token = _locationOp.begin();
    emit(
      state.copyWith(
        status: CoverageAreaStatus.loading,
        clearFailure: true,
      ),
    );

    final result = await _getCurrentLocationUseCase(const NoParams()).run();
    if (!_locationOp.isCurrent(token)) return;

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
          token: token,
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
    int? token,
  }) async {
    final resolvedToken = token ?? _locationOp.begin();
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

    final intent = CoverageLocationIntent(
      center: center,
      radiusKm: resolvedRadius,
      localeIdentifier: _localeIdentifier,
      cityId: _cityId,
    );

    final result = await _resolveCoverageLocationUseCase(intent).run();
    if (!_locationOp.isCurrent(resolvedToken)) return;

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
        final areas = location.nearbyAreas
            .where((area) => !_removedAutoAreaNames.contains(area.name))
            .toList(growable: false);
        _autoAreasController.replace(areas);
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

  @override
  Future<void> close() {
    _autoAreasController.dispose();
    _extraAreasController.dispose();
    return super.close();
  }
}
