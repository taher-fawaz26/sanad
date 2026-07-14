import 'package:equatable/equatable.dart';

class RadiusPreset extends Equatable {
  const RadiusPreset({required this.label, required this.radiusKm});

  final String label;
  final double radiusKm;

  static const defaultPresets = [
    RadiusPreset(label: '1 km', radiusKm: 1),
    RadiusPreset(label: '3 km', radiusKm: 3),
    RadiusPreset(label: '5 km', radiusKm: 5),
    RadiusPreset(label: '10 km', radiusKm: 10),
    RadiusPreset(label: '15 km', radiusKm: 15),
    RadiusPreset(label: '20 km', radiusKm: 20),
  ];

  @override
  List<Object?> get props => [label, radiusKm];
}
