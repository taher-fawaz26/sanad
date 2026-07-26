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
    this.isoCountryCode,
    this.failure,
    this.cameraSource = LocationPickerCameraSource.none,
    this.predictions = const [],
    this.searchStatus = PlaceSearchStatus.idle,
    this.searchError,
    this.searchQuery = '',
  });

  /// Country the picked location must belong to (the UAE).
  static const allowedCountryCode = 'AE';

  final LocationPickerStatus status;
  final LatLng? position;
  final String? address;

  /// ISO country of [position] (uppercased), when known.
  final String? isoCountryCode;
  final Failure? failure;
  final LocationPickerCameraSource cameraSource;
  final List<PlacePrediction> predictions;
  final PlaceSearchStatus searchStatus;
  final String? searchError;
  final String searchQuery;

  /// True only when the pin is *known* to be in another country — a null
  /// geocode never blocks a legitimate in-country point.
  bool get isOutsideCountry =>
      status == LocationPickerStatus.ready &&
      position != null &&
      isoCountryCode != null &&
      isoCountryCode!.toUpperCase() != allowedCountryCode;

  bool get canConfirm =>
      position != null &&
      address != null &&
      address!.isNotEmpty &&
      status == LocationPickerStatus.ready &&
      !isOutsideCountry;

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
    String? Function()? isoCountryCode,
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
      isoCountryCode: isoCountryCode != null
          ? isoCountryCode()
          : this.isoCountryCode,
      failure: clearFailure ? null : (failure ?? this.failure),
      cameraSource: cameraSource ?? this.cameraSource,
      predictions: clearPredictions
          ? const []
          : (predictions ?? this.predictions),
      searchStatus:
          searchStatus ??
          (clearPredictions ? PlaceSearchStatus.idle : this.searchStatus),
      searchError:
          searchError ??
          (clearSearchError || clearPredictions ? null : this.searchError),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    status,
    position,
    address,
    isoCountryCode,
    failure,
    cameraSource,
    predictions,
    searchStatus,
    searchError,
    searchQuery,
  ];
}
