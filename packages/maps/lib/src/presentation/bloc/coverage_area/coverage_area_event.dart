part of 'coverage_area_bloc.dart';

sealed class CoverageAreaEvent extends Equatable {
  const CoverageAreaEvent();

  @override
  List<Object?> get props => [];
}

final class CoverageAreaStarted extends CoverageAreaEvent {
  const CoverageAreaStarted({
    this.initialPosition,
    this.initialAddress,
    this.initialRadiusKm,
    this.initialServingAreas = const [],
    this.localeIdentifier,
  });

  final LatLng? initialPosition;
  final String? initialAddress;
  final double? initialRadiusKm;
  final List<ServingArea> initialServingAreas;
  final String? localeIdentifier;

  @override
  List<Object?> get props => [
        initialPosition,
        initialAddress,
        initialRadiusKm,
        initialServingAreas,
        localeIdentifier,
      ];
}

final class CoverageAreaLocationUpdated extends CoverageAreaEvent {
  const CoverageAreaLocationUpdated({
    required this.position,
    this.address,
  });

  final LatLng position;
  final String? address;

  @override
  List<Object?> get props => [position, address];
}

final class CoverageAreaCameraIdle extends CoverageAreaEvent {
  const CoverageAreaCameraIdle(this.position);

  final LatLng position;

  @override
  List<Object?> get props => [position];
}

final class CoverageAreaSearchSubmitted extends CoverageAreaEvent {
  const CoverageAreaSearchSubmitted(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class CoverageAreaRadiusChanged extends CoverageAreaEvent {
  const CoverageAreaRadiusChanged(this.radiusKm);

  final double radiusKm;

  @override
  List<Object?> get props => [radiusKm];
}

final class CoverageAreaServingAreaAdded extends CoverageAreaEvent {
  const CoverageAreaServingAreaAdded(this.area);

  final ServingArea area;

  @override
  List<Object?> get props => [area];
}

final class CoverageAreaServingAreaRemoved extends CoverageAreaEvent {
  const CoverageAreaServingAreaRemoved(this.placeId);

  final String placeId;

  @override
  List<Object?> get props => [placeId];
}

final class CoverageAreaQueryChanged extends CoverageAreaEvent {
  const CoverageAreaQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class CoverageAreaPredictionSelected extends CoverageAreaEvent {
  const CoverageAreaPredictionSelected(this.prediction);

  final PlacePrediction prediction;

  @override
  List<Object?> get props => [prediction];
}

final class CoverageAreaPredictionsCleared extends CoverageAreaEvent {
  const CoverageAreaPredictionsCleared();
}
