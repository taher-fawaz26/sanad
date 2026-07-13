import 'package:branches/src/domain/usecases/get_current_location_usecase.dart';
import 'package:branches/src/domain/usecases/open_location_settings_usecase.dart';
import 'package:branches/src/domain/usecases/reverse_geocode_usecase.dart';
import 'package:branches/src/domain/usecases/search_location_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/maps.dart';

part 'location_picker_event.dart';
part 'location_picker_state.dart';

class LocationPickerBloc
    extends Bloc<LocationPickerEvent, LocationPickerState> {
  LocationPickerBloc({
    required GetCurrentLocationUseCase getCurrentLocationUseCase,
    required ReverseGeocodeUseCase reverseGeocodeUseCase,
    required SearchLocationUseCase searchLocationUseCase,
    required OpenLocationSettingsUseCase openLocationSettingsUseCase,
  })  : _getCurrentLocationUseCase = getCurrentLocationUseCase,
        _reverseGeocodeUseCase = reverseGeocodeUseCase,
        _searchLocationUseCase = searchLocationUseCase,
        _openLocationSettingsUseCase = openLocationSettingsUseCase,
        super(const LocationPickerState()) {
    on<LocationPickerStarted>(_onStarted);
    on<LocationPickerCameraIdle>(_onCameraIdle);
    on<LocationPickerSearchSubmitted>(_onSearchSubmitted);
    on<LocationPickerSettingsRequested>(_onSettingsRequested);
  }

  final GetCurrentLocationUseCase _getCurrentLocationUseCase;
  final ReverseGeocodeUseCase _reverseGeocodeUseCase;
  final SearchLocationUseCase _searchLocationUseCase;
  final OpenLocationSettingsUseCase _openLocationSettingsUseCase;

  Future<void> _onStarted(
    LocationPickerStarted event,
    Emitter<LocationPickerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: LocationPickerStatus.loadingLocation,
        clearFailure: true,
      ),
    );

    final result = await _getCurrentLocationUseCase(const NoParams()).run();

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
        await _reverseGeocode(position, emit);
      },
    );
  }

  Future<void> _onCameraIdle(
    LocationPickerCameraIdle event,
    Emitter<LocationPickerState> emit,
  ) async {
    if (state.status == LocationPickerStatus.loadingLocation) return;

    emit(
      state.copyWith(
        status: LocationPickerStatus.geocoding,
        position: event.position,
        cameraSource: LocationPickerCameraSource.user,
        clearFailure: true,
      ),
    );

    await _reverseGeocode(event.position, emit);
  }

  Future<void> _onSearchSubmitted(
    LocationPickerSearchSubmitted event,
    Emitter<LocationPickerState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    emit(
      state.copyWith(
        status: LocationPickerStatus.geocoding,
        clearFailure: true,
      ),
    );

    final result = await _searchLocationUseCase(
      SearchLocationParams(query: query),
    ).run();

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
        await _reverseGeocode(position, emit);
      },
    );
  }

  Future<void> _onSettingsRequested(
    LocationPickerSettingsRequested event,
    Emitter<LocationPickerState> emit,
  ) async {
    await _openLocationSettingsUseCase(const NoParams()).run();
  }

  Future<void> _reverseGeocode(
    LatLng position,
    Emitter<LocationPickerState> emit,
  ) async {
    final result = await _reverseGeocodeUseCase(
      ReverseGeocodeParams(position: position),
    ).run();

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
