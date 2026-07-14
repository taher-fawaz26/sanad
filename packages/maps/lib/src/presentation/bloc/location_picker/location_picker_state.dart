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
    this.predictions = const [],
    this.searchStatus = PlaceSearchStatus.idle,
    this.searchError,
    this.searchQuery = '',
  });

  final LocationPickerStatus status;
  final LatLng? position;
  final String? address;
  final Failure? failure;
  final LocationPickerCameraSource cameraSource;
  final List<PlacePrediction> predictions;
  final PlaceSearchStatus searchStatus;
  final String? searchError;
  final String searchQuery;

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

  bool get hasPredictions => predictions.isNotEmpty;

  bool get isSearching => searchStatus == PlaceSearchStatus.searching;

  LocationPickerState copyWith({
    LocationPickerStatus? status,
    LatLng? position,
    String? address,
    Failure? failure,
    LocationPickerCameraSource? cameraSource,
    List<PlacePrediction>? predictions,
    PlaceSearchStatus? searchStatus,
    String? searchError,
    String? searchQuery,
    bool clearFailure = false,
    bool clearAddress = false,
    bool clearPredictions = false,
    bool clearSearchError = false,
  }) {
    return LocationPickerState(
      status: status ?? this.status,
      position: position ?? this.position,
      address: clearAddress ? null : (address ?? this.address),
      failure: clearFailure ? null : (failure ?? this.failure),
      cameraSource: cameraSource ?? this.cameraSource,
      predictions:
          clearPredictions ? const [] : (predictions ?? this.predictions),
      searchStatus: searchStatus ??
          (clearPredictions ? PlaceSearchStatus.idle : this.searchStatus),
      searchError: searchError ??
          (clearSearchError || clearPredictions ? null : this.searchError),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        status,
        position,
        address,
        failure,
        cameraSource,
        predictions,
        searchStatus,
        searchError,
        searchQuery,
      ];
}
