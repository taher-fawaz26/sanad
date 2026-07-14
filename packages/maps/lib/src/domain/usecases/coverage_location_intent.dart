import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

sealed class CoverageLocationIntent extends Equatable {
  const CoverageLocationIntent({
    required this.center,
    required this.radiusKm,
    this.localeIdentifier,
  });

  final LatLng center;
  final double radiusKm;
  final String? localeIdentifier;

  @override
  List<Object?> get props => [center, radiusKm, localeIdentifier];
}

final class CreateCoverageIntent extends CoverageLocationIntent {
  const CreateCoverageIntent({
    required super.center,
    required super.radiusKm,
    super.localeIdentifier,
  });
}

final class EditCoverageIntent extends CoverageLocationIntent {
  const EditCoverageIntent({
    required this.branchId,
    required super.center,
    required super.radiusKm,
    super.localeIdentifier,
  });

  final String branchId;

  @override
  List<Object?> get props => [...super.props, branchId];
}

final class RecalculateCoverageIntent extends CoverageLocationIntent {
  const RecalculateCoverageIntent({
    required this.branchId,
    required super.center,
    required super.radiusKm,
    super.localeIdentifier,
  });

  final String branchId;

  @override
  List<Object?> get props => [...super.props, branchId];
}
