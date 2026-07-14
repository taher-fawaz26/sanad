part of 'coverage_area_bloc.dart';

sealed class CoverageAreaEvent extends Equatable {
  const CoverageAreaEvent();

  @override
  List<Object?> get props => [];
}

final class CoverageAreaStarted extends CoverageAreaEvent {
  const CoverageAreaStarted({
    required this.mode,
    this.branchId,
    this.initialCenter,
    this.initialAddress,
    this.initialRadiusKm,
    this.initialExtraArea,
    this.localeIdentifier,
  });

  final CoverageMode mode;
  final String? branchId;
  final LatLng? initialCenter;
  final String? initialAddress;
  final double? initialRadiusKm;
  final ServingArea? initialExtraArea;
  final String? localeIdentifier;

  @override
  List<Object?> get props => [
        mode,
        branchId,
        initialCenter,
        initialAddress,
        initialRadiusKm,
        initialExtraArea,
        localeIdentifier,
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
  const CoverageAreaExtraAreaRemoved();
}
