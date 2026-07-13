part of 'location_picker_bloc.dart';

enum LocationPickerStatus {
  initial,
  loadingLocation,
  ready,
  geocoding,
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  failure,
}

enum LocationPickerCameraSource {
  none,
  programmatic,
  user,
}

class LocationPickerState extends Equatable {
  const LocationPickerState({
    this.status = LocationPickerStatus.initial,
    this.position,
    this.address,
    this.failure,
    this.cameraSource = LocationPickerCameraSource.none,
  });

  final LocationPickerStatus status;
  final LatLng? position;
  final String? address;
  final Failure? failure;
  final LocationPickerCameraSource cameraSource;

  bool get canConfirm =>
      position != null &&
      address != null &&
      address!.isNotEmpty &&
      status == LocationPickerStatus.ready;

  bool get isLoadingMap =>
      status == LocationPickerStatus.loadingLocation ||
      status == LocationPickerStatus.initial;

  bool get isGeocoding => status == LocationPickerStatus.geocoding;

  bool get hasPermissionError =>
      status == LocationPickerStatus.permissionDenied ||
      status == LocationPickerStatus.permissionPermanentlyDenied ||
      status == LocationPickerStatus.serviceDisabled;

  LocationPickerState copyWith({
    LocationPickerStatus? status,
    LatLng? position,
    String? address,
    Failure? failure,
    LocationPickerCameraSource? cameraSource,
    bool clearFailure = false,
    bool clearAddress = false,
  }) {
    return LocationPickerState(
      status: status ?? this.status,
      position: position ?? this.position,
      address: clearAddress ? null : (address ?? this.address),
      failure: clearFailure ? null : (failure ?? this.failure),
      cameraSource: cameraSource ?? this.cameraSource,
    );
  }

  @override
  List<Object?> get props => [
        status,
        position,
        address,
        failure,
        cameraSource,
      ];
}
