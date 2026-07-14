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
    this.localeIdentifier,
  });

  final LatLng? initialPosition;
  final String? initialAddress;
  final double? initialRadiusKm;
  final String? localeIdentifier;

  @override
  List<Object?> get props => [
        initialPosition,
        initialAddress,
        initialRadiusKm,
        localeIdentifier,
      ];
}

final class CoverageAreaLocationUpdated extends CoverageAreaEvent {
  const CoverageAreaLocationUpdated({
    required this.position,
    required this.address,
  });

  final LatLng position;
  final String address;

  @override
  List<Object?> get props => [position, address];
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

final class CoverageAreaAreaRemoved extends CoverageAreaEvent {
  const CoverageAreaAreaRemoved(this.area);

  final String area;

  @override
  List<Object?> get props => [area];
}

final class CoverageAreaAreaAdded extends CoverageAreaEvent {
  const CoverageAreaAreaAdded(this.area);

  final String area;

  @override
  List<Object?> get props => [area];
}
