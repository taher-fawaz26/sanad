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
    this.suggestedAreas = const [],
    this.customAreas = const [],
    this.removedAreas = const {},
    this.failure,
    this.cameraSource = CoverageAreaCameraSource.none,
  });

  static const double defaultRadiusKm = 5;

  final CoverageAreaStatus status;
  final LatLng? position;
  final String? address;
  final double radiusKm;
  final List<String> suggestedAreas;
  final List<String> customAreas;
  final Set<String> removedAreas;
  final Failure? failure;
  final CoverageAreaCameraSource cameraSource;

  List<String> get coveredAreas => [
        ...suggestedAreas.where((area) => !removedAreas.contains(area)),
        ...customAreas,
      ];

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
    List<String>? suggestedAreas,
    List<String>? customAreas,
    Set<String>? removedAreas,
    Failure? failure,
    CoverageAreaCameraSource? cameraSource,
    bool clearFailure = false,
    bool clearAddress = false,
    bool resetAreas = false,
  }) {
    return CoverageAreaState(
      status: status ?? this.status,
      position: position ?? this.position,
      address: clearAddress ? null : (address ?? this.address),
      radiusKm: radiusKm ?? this.radiusKm,
      suggestedAreas: resetAreas
          ? const []
          : (suggestedAreas ?? this.suggestedAreas),
      customAreas:
          resetAreas ? const [] : (customAreas ?? this.customAreas),
      removedAreas:
          resetAreas ? const {} : (removedAreas ?? this.removedAreas),
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
        suggestedAreas,
        customAreas,
        removedAreas,
        failure,
        cameraSource,
      ];
}
