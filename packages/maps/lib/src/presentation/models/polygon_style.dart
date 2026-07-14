import 'dart:ui';

import 'package:equatable/equatable.dart';

class PolygonStyle extends Equatable {
  const PolygonStyle({
    this.strokeWidth = 2,
    this.strokeColor = const Color(0xFF000000),
    this.fillColor = const Color(0x33000000),
    this.geodesic = false,
  });

  final int strokeWidth;
  final Color strokeColor;
  final Color fillColor;
  final bool geodesic;

  @override
  List<Object?> get props => [strokeWidth, strokeColor, fillColor, geodesic];
}
