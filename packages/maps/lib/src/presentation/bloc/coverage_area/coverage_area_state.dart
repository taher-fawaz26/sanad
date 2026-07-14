part of 'coverage_area_bloc.dart';

enum CoverageAreaStatus {
  initial,
  loading,
  ready,
  failure,
}

enum CoverageAreaCameraSource {
  none,
  programmatic,
}

class CoverageAreaState extends Equatable {
  const CoverageAreaState({
    this.status = CoverageAreaStatus.initial,
    this.position,
    this.address,
    this.radiusKm = defaultRadiusKm,
    this.servingAreas = const [],
    this.predictions = const [],
    this.searchStatus = PlaceSearchStatus.idle,
    this.searchQuery = '',
    this.searchError,
    this.failure,
    this.cameraSource = CoverageAreaCameraSource.none,
  });

  static const double defaultRadiusKm = 5;

  final CoverageAreaStatus status;
  final LatLng? position;
  final String? address;
  final double radiusKm;
  final List<ServingArea> servingAreas;
  final List<PlacePrediction> predictions;
  final PlaceSearchStatus searchStatus;
  final String searchQuery;
  final String? searchError;
  final Failure? failure;
  final CoverageAreaCameraSource cameraSource;

  bool get canConfirm =>
      position != null &&
      address != null &&
      address!.isNotEmpty &&
      status == CoverageAreaStatus.ready;

  bool get isLoading => status == CoverageAreaStatus.loading;

  CoverageAreaState copyWith({
    CoverageAreaStatus? status,
    LatLng? position,
    String? address,
    double? radiusKm,
    List<ServingArea>? servingAreas,
    List<PlacePrediction>? predictions,
    PlaceSearchStatus? searchStatus,
    String? searchQuery,
    String? searchError,
    Failure? failure,
    CoverageAreaCameraSource? cameraSource,
    bool clearFailure = false,
    bool clearAddress = false,
    bool clearSearchError = false,
  }) {
    return CoverageAreaState(
      status: status ?? this.status,
      position: position ?? this.position,
      address: clearAddress ? null : (address ?? this.address),
      radiusKm: radiusKm ?? this.radiusKm,
      servingAreas: servingAreas ?? this.servingAreas,
      predictions: predictions ?? this.predictions,
      searchStatus: searchStatus ?? this.searchStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      searchError:
          clearSearchError ? null : (searchError ?? this.searchError),
      failure: clearFailure ? null : (failure ?? this.failure),
      cameraSource: cameraSource ?? this.cameraSource,
    );
  }

  @override
  List<Object?> get props => [
        status,
        position,
        address,
        radiusKm,
        servingAreas,
        predictions,
        searchStatus,
        searchQuery,
        searchError,
        failure,
        cameraSource,
      ];
}
