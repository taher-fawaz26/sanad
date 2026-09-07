part of 'location_picker_bloc.dart';

sealed class LocationPickerEvent extends Equatable {
  const LocationPickerEvent();

  @override
  List<Object?> get props => [];
}

final class LocationPickerStarted extends LocationPickerEvent {
  const LocationPickerStarted({
    this.initialPosition,
    this.initialAddress,
    this.initialPlaceId,
    this.localeIdentifier,
  });

  final LatLng? initialPosition;
  final String? initialAddress;

  /// A previously saved Google Place ID (edit-reopen). Seeds
  /// [LocationPickerState.selectedPlaceId] so a reopened, already-complete
  /// selection is confirmable immediately without re-resolving or nudging the
  /// pin (SAN-778 follow-up).
  final String? initialPlaceId;

  final String? localeIdentifier;

  @override
  List<Object?> get props => [
    initialPosition,
    initialAddress,
    initialPlaceId,
    localeIdentifier,
  ];
}

final class LocationPickerCameraIdle extends LocationPickerEvent {
  const LocationPickerCameraIdle(this.position);

  final LatLng position;

  @override
  List<Object?> get props => [position];
}

final class LocationPickerSearchSubmitted extends LocationPickerEvent {
  const LocationPickerSearchSubmitted(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class LocationPickerSettingsRequested extends LocationPickerEvent {
  const LocationPickerSettingsRequested();
}

final class LocationPickerQueryChanged extends LocationPickerEvent {
  const LocationPickerQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class LocationPickerPredictionSelected extends LocationPickerEvent {
  const LocationPickerPredictionSelected(this.prediction);

  final PlacePrediction prediction;

  @override
  List<Object?> get props => [prediction];
}

final class LocationPickerPredictionsCleared extends LocationPickerEvent {
  const LocationPickerPredictionsCleared();
}

/// Internal — dispatched once [CheckLocationPermissionUseCase] resolves.
///
/// Fired fire-and-forget from [LocationPickerStarted] so the permission check
/// never delays the initial ready/geocoding state.
final class LocationPickerPermissionChecked extends LocationPickerEvent {
  const LocationPickerPermissionChecked(this.status);

  final LocationPermissionStatus status;

  @override
  List<Object?> get props => [status];
}

/// The user tapped "use my current location" (the crosshair). Owns the whole
/// current-location sequence — permission/service resolution, GPS fetch,
/// supported-area validation, camera move and reverse-geocode — inside the
/// bloc so there is a single state machine, one in-flight guard against
/// duplicate taps, and lifecycle-aware recovery (SAN-778).
final class LocationPickerCurrentLocationRequested extends LocationPickerEvent {
  const LocationPickerCurrentLocationRequested();
}

/// The app returned to the foreground (e.g. back from system Settings). Clears
/// a stale current-location failure and re-checks permission so returning
/// after enabling location/permission recovers without a restart or an
/// arbitrary delay (SAN-778).
final class LocationPickerResumed extends LocationPickerEvent {
  const LocationPickerResumed();
}

/// Opens the OS *device location* settings (the global GPS toggle) — the
/// recovery action offered when location services are switched off.
final class LocationPickerDeviceSettingsRequested extends LocationPickerEvent {
  const LocationPickerDeviceSettingsRequested();
}

/// Re-runs reverse-geocoding for the currently selected [LocationPickerState.
/// position] — the retry action after an address lookup failed. No-op when
/// there is no position to resolve (SAN-778).
final class LocationPickerRetryGeocode extends LocationPickerEvent {
  const LocationPickerRetryGeocode();
}
