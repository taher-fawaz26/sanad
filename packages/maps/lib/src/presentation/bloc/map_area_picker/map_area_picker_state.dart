part of 'map_area_picker_bloc.dart';

enum MapAreaPickerStatus {
  initial,
  geocoding,
  ready,
  failure,
}

enum MapAreaPickerCameraSource {
  none,
  programmatic,
  user,
}

class MapAreaPickerState extends Equatable {
  const MapAreaPickerState({
    this.status = MapAreaPickerStatus.initial,
    this.position,
    this.address,
    this.failure,
    this.cameraSource = MapAreaPickerCameraSource.none,
    this.selectedPlaceId,
    this.selectedTitle,
    this.resolvedAreaName,
    this.predictions = const [],
    this.searchStatus = PlaceSearchStatus.idle,
    this.searchQuery = '',
    this.searchError,
    this.pickedResult,
  });

  final MapAreaPickerStatus status;
  final LatLng? position;
  final String? address;
  final Failure? failure;
  final MapAreaPickerCameraSource cameraSource;
  final String? selectedPlaceId;
  final String? selectedTitle;

  /// Human-friendly area name from reverse-geocoding the current [position]
  /// (used as the picked area label when no Places prediction was selected).
  final String? resolvedAreaName;
  final List<PlacePrediction> predictions;
  final PlaceSearchStatus searchStatus;
  final String searchQuery;
  final String? searchError;
  final MapAreaPickerResult? pickedResult;

  bool get canConfirm =>
      position != null && address != null && address!.isNotEmpty;

  bool get isGeocoding => status == MapAreaPickerStatus.geocoding;

  MapAreaPickerState copyWith({
    MapAreaPickerStatus? status,
    LatLng? position,
    String? address,
    Failure? failure,
    MapAreaPickerCameraSource? cameraSource,
    String? selectedPlaceId,
    String? selectedTitle,
    String? resolvedAreaName,
    List<PlacePrediction>? predictions,
    PlaceSearchStatus? searchStatus,
    String? searchQuery,
    String? searchError,
    MapAreaPickerResult? pickedResult,
    bool clearFailure = false,
    bool clearAddress = false,
    bool clearPredictions = false,
    bool clearSearchError = false,
    bool clearSelectedPlace = false,
    bool clearPickedResult = false,
  }) {
    return MapAreaPickerState(
      status: status ?? this.status,
      position: position ?? this.position,
      address: clearAddress ? null : (address ?? this.address),
      failure: clearFailure ? null : (failure ?? this.failure),
      cameraSource: cameraSource ?? this.cameraSource,
      selectedPlaceId: clearSelectedPlace
          ? null
          : (selectedPlaceId ?? this.selectedPlaceId),
      selectedTitle: clearSelectedPlace
          ? null
          : (selectedTitle ?? this.selectedTitle),
      resolvedAreaName: resolvedAreaName ?? this.resolvedAreaName,
      predictions: clearPredictions
          ? const []
          : (predictions ?? this.predictions),
      searchStatus:
          searchStatus ??
          (clearPredictions ? PlaceSearchStatus.idle : this.searchStatus),
      searchQuery: searchQuery ?? this.searchQuery,
      searchError:
          searchError ??
          (clearSearchError || clearPredictions ? null : this.searchError),
      pickedResult: clearPickedResult
          ? null
          : (pickedResult ?? this.pickedResult),
    );
  }

  @override
  List<Object?> get props => [
    status,
    position,
    address,
    failure,
    cameraSource,
    selectedPlaceId,
    selectedTitle,
    resolvedAreaName,
    predictions,
    searchStatus,
    searchQuery,
    searchError,
    pickedResult,
  ];
}
