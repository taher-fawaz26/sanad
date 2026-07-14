import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolylineStyle extends Equatable {
  const PolylineStyle({
    this.width = 4,
    this.color = const Color(0xFF000000),
    this.geodesic = false,
    this.patterns = const [],
  });

  final int width;
  final Color color;
  final bool geodesic;
  final List<PatternItem> patterns;

  @override
  List<Object?> get props => [width, color, geodesic, patterns];
}
