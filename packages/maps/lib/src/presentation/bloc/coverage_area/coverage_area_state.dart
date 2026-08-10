part of 'coverage_area_bloc.dart';

enum CoverageAreaStatus {
  initial,
  loading,
  ready,
  failure,
}

/// Status of the Google-only area *discovery* specifically — distinct from
/// [CoverageAreaStatus], which tracks the center/address readiness that
/// gates [CoverageAreaState.canConfirm]. A discovery can fail or come back
/// empty/partial while the location itself is still perfectly resolved.
enum CoverageAreaDiscoveryStatus {
  initial,
  loading,
  success,
  empty,
  partialFailure,
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
    this.isoCountryCode,
    this.radiusKm = defaultRadiusKm,
    this.mode = CoverageMode.create,
    this.autoAreas = const [],
    this.extraAreas = const [],
    this.failure,
    this.cameraSource = CoverageAreaCameraSource.none,
    this.discoveryStatus = CoverageAreaDiscoveryStatus.initial,
  });

  static const double defaultRadiusKm = 5;

  /// Country the coverage centre must belong to. Selection outside it is
  /// blocked so branches only cover the supported country (the UAE).
  static const allowedCountryCode = 'AE';

  final CoverageAreaStatus status;
  final LatLng? center;
  final String? address;

  /// ISO country of [center] (uppercased), when known.
  final String? isoCountryCode;
  final double radiusKm;
  final CoverageMode mode;
  final List<ServingArea> autoAreas;
  final List<ServingArea> extraAreas;
  final Failure? failure;
  final CoverageAreaCameraSource cameraSource;
  final CoverageAreaDiscoveryStatus discoveryStatus;

  /// True only when the centre is *known* to be in another country — a null
  /// geocode never blocks a legitimate in-country point.
  bool get isOutsideCountry =>
      status == CoverageAreaStatus.ready &&
      center != null &&
      isoCountryCode != null &&
      isoCountryCode!.toUpperCase() != allowedCountryCode;

  bool get canConfirm =>
      center != null &&
      address != null &&
      address!.isNotEmpty &&
      status == CoverageAreaStatus.ready &&
      !isOutsideCountry;

  bool get isLoading => status == CoverageAreaStatus.loading;

  int get totalAreaCount => autoAreas.length + extraAreas.length;

  List<ServingArea> get allServingAreas => [...autoAreas, ...extraAreas];

  CoverageAreaState copyWith({
    CoverageAreaStatus? status,
    LatLng? center,
    String? address,
    String? Function()? isoCountryCode,
    double? radiusKm,
    CoverageMode? mode,
    List<ServingArea>? autoAreas,
    List<ServingArea>? extraAreas,
    Failure? failure,
    CoverageAreaCameraSource? cameraSource,
    CoverageAreaDiscoveryStatus? discoveryStatus,
    bool clearFailure = false,
    bool clearAddress = false,
  }) {
    return CoverageAreaState(
      status: status ?? this.status,
      center: center ?? this.center,
      address: clearAddress ? null : (address ?? this.address),
      isoCountryCode: isoCountryCode != null
          ? isoCountryCode()
          : this.isoCountryCode,
      radiusKm: radiusKm ?? this.radiusKm,
      mode: mode ?? this.mode,
      autoAreas: autoAreas ?? this.autoAreas,
      extraAreas: extraAreas ?? this.extraAreas,
      failure: clearFailure ? null : (failure ?? this.failure),
      cameraSource: cameraSource ?? this.cameraSource,
      discoveryStatus: discoveryStatus ?? this.discoveryStatus,
    );
  }

  @override
  List<Object?> get props => [
    status,
    center,
    address,
    isoCountryCode,
    radiusKm,
    mode,
    autoAreas,
    extraAreas,
    failure,
    cameraSource,
    discoveryStatus,
  ];
}
