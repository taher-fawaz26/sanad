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
    this.hasLocationPermission = false,
    this.selectedPlaceId,
    this.isLocating = false,
    this.currentLocationFailure,
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

  /// Whether location permission is currently granted. Only ever flips to
  /// true from a passive [CheckLocationPermissionUseCase] check — never
  /// implies a permission request was made. Gates [AppGoogleMap]'s
  /// `myLocationEnabled` so the MyLocation layer is never requested before
  /// permission is actually granted.
  final bool hasLocationPermission;

  /// Google Places Autocomplete place ID from the most recent prediction
  /// selection. Cleared when the user drags the map or uses forward geocode,
  /// because those flows produce coordinates without a Google Place ID.
  final String? selectedPlaceId;

  /// True while the "use my current location" (crosshair) request is in flight
  /// — from permission/service resolution through the GPS fetch. Transient and
  /// deliberately separate from [status] so a running (or failed) GPS attempt
  /// never clobbers an already-valid selection or its address (SAN-778).
  final bool isLocating;

  /// The most recent "use my current location" failure. Surfaced to the user
  /// as a localized message + recovery action WITHOUT destroying a valid
  /// [status]/[position]/[address] — a failed GPS attempt must leave any
  /// previously selected location intact (SAN-778). Cleared on the next
  /// attempt, on success, and on app resume.
  final Failure? currentLocationFailure;

  /// A selection is present and confirmable on its own terms — used to decide
  /// whether a current-location failure is shown inline (no selection yet) or
  /// as a transient snackbar (an existing selection must be preserved).
  bool get hasResolvedSelection =>
      status == LocationPickerStatus.ready &&
      position != null &&
      address != null &&
      address!.isNotEmpty;

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
    bool? hasLocationPermission,
    String? Function()? selectedPlaceId,
    bool? isLocating,
    Failure? currentLocationFailure,
    bool clearFailure = false,
    bool clearAddress = false,
    bool clearPredictions = false,
    bool clearSearchError = false,
    bool clearSelectedPlaceId = false,
    bool clearCurrentLocationFailure = false,
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
      hasLocationPermission:
          hasLocationPermission ?? this.hasLocationPermission,
      selectedPlaceId: clearSelectedPlaceId
          ? null
          : (selectedPlaceId != null
                ? selectedPlaceId()
                : this.selectedPlaceId),
      isLocating: isLocating ?? this.isLocating,
      currentLocationFailure: clearCurrentLocationFailure
          ? null
          : (currentLocationFailure ?? this.currentLocationFailure),
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
    hasLocationPermission,
    selectedPlaceId,
    isLocating,
    currentLocationFailure,
  ];
}
