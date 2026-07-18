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
    this.center,
    this.address,
    this.radiusKm = defaultRadiusKm,
    this.mode = CoverageMode.create,
    this.autoAreas = const [],
    this.extraAreas = const [],
    this.failure,
    this.cameraSource = CoverageAreaCameraSource.none,
  });

  static const double defaultRadiusKm = 5;

  final CoverageAreaStatus status;
  final LatLng? center;
  final String? address;
  final double radiusKm;
  final CoverageMode mode;
  final List<ServingArea> autoAreas;
  final List<ServingArea> extraAreas;
  final Failure? failure;
  final CoverageAreaCameraSource cameraSource;

  bool get canConfirm =>
      center != null &&
      address != null &&
      address!.isNotEmpty &&
      status == CoverageAreaStatus.ready;

  bool get isLoading => status == CoverageAreaStatus.loading;

  int get totalAreaCount => autoAreas.length + extraAreas.length;

  List<ServingArea> get allServingAreas => [...autoAreas, ...extraAreas];

  CoverageAreaState copyWith({
    CoverageAreaStatus? status,
    LatLng? center,
    String? address,
    double? radiusKm,
    CoverageMode? mode,
    List<ServingArea>? autoAreas,
    List<ServingArea>? extraAreas,
    Failure? failure,
    CoverageAreaCameraSource? cameraSource,
    bool clearFailure = false,
    bool clearAddress = false,
  }) {
    return CoverageAreaState(
      status: status ?? this.status,
      center: center ?? this.center,
      address: clearAddress ? null : (address ?? this.address),
      radiusKm: radiusKm ?? this.radiusKm,
      mode: mode ?? this.mode,
      autoAreas: autoAreas ?? this.autoAreas,
      extraAreas: extraAreas ?? this.extraAreas,
      failure: clearFailure ? null : (failure ?? this.failure),
      cameraSource: cameraSource ?? this.cameraSource,
    );
  }

  @override
  List<Object?> get props => [
    status,
    center,
    address,
    radiusKm,
    mode,
    autoAreas,
    extraAreas,
    failure,
    cameraSource,
  ];
}
