part of 'coverage_area_bloc.dart';

sealed class CoverageAreaEvent extends Equatable {
  const CoverageAreaEvent();

  @override
  List<Object?> get props => [];
}

final class CoverageAreaStarted extends CoverageAreaEvent {
  const CoverageAreaStarted({
    required this.mode,
    this.initialCenter,
    this.initialAddress,
    this.initialRadiusKm,
    this.initialAutoAreas = const <ServingArea>[],
    this.initialExtraAreas = const [],
    this.localeIdentifier,
    this.cityId,
  });

  final CoverageMode mode;
  final LatLng? initialCenter;
  final String? initialAddress;
  final double? initialRadiusKm;

  /// Pre-existing areas to seed in [CoverageMode.edit]. The consuming feature
  /// loads these (e.g. a branch's saved serving areas) and passes them in; the
  /// maps platform never fetches them itself.
  final List<ServingArea> initialAutoAreas;
  final List<ServingArea> initialExtraAreas;
  final String? localeIdentifier;
  final String? cityId;

  @override
  List<Object?> get props => [
    mode,
    initialCenter,
    initialAddress,
    initialRadiusKm,
    initialAutoAreas,
    initialExtraAreas,
    localeIdentifier,
    cityId,
  ];
}

final class CoverageAreaMapMoved extends CoverageAreaEvent {
  const CoverageAreaMapMoved(
    this.center, {
    this.cameraSource = CoverageAreaCameraSource.none,
  });

  final LatLng center;
  final CoverageAreaCameraSource cameraSource;

  @override
  List<Object?> get props => [center, cameraSource];
}

final class CoverageAreaCurrentLocationRequested extends CoverageAreaEvent {
  const CoverageAreaCurrentLocationRequested();
}

final class CoverageAreaRadiusChanged extends CoverageAreaEvent {
  const CoverageAreaRadiusChanged(this.radiusKm);

  final double radiusKm;

  @override
  List<Object?> get props => [radiusKm];
}

final class CoverageAreaAutoAreaRemoved extends CoverageAreaEvent {
  const CoverageAreaAutoAreaRemoved(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class CoverageAreaExtraAreaSet extends CoverageAreaEvent {
  const CoverageAreaExtraAreaSet(this.area);

  final ServingArea area;

  @override
  List<Object?> get props => [area];
}

final class CoverageAreaExtraAreaRemoved extends CoverageAreaEvent {
  const CoverageAreaExtraAreaRemoved(this.area);

  final ServingArea area;

  @override
  List<Object?> get props => [area];
}
