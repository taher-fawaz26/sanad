import 'package:equatable/equatable.dart';

class RadiusOverlayStyle extends Equatable {
  const RadiusOverlayStyle({
    this.strokeWidth = 4,
    this.fillAlpha = 0.0,
    this.circleId = 'radius_overlay',
  });

  final int strokeWidth;
  final double fillAlpha;
  final String circleId;

  @override
  List<Object?> get props => [strokeWidth, fillAlpha, circleId];
}
