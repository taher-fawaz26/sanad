import 'dart:math' as math;

import 'package:bottom_nav_bar/src/theme/bottom_nav_theme_data.dart';
import 'package:flutter/material.dart';

/// Builds the bottom bar path with a fixed-center C¹ smooth notch cutout.
Path buildBottomNavBarPath({
  required Size size,
  required double notchCX,
  required double notchR,
  required double fabSink,
  required double notchShoulderRadius,
  required double cornerRadius,
}) {
  final barPath = Path()
    ..addRRect(
      RRect.fromLTRBAndCorners(
        0,
        0,
        size.width,
        size.height,
        topLeft: Radius.circular(cornerRadius),
        topRight: Radius.circular(cornerRadius),
      ),
    );

  final notchCutout = Path();
  final shoulder = notchShoulderRadius;

  if (shoulder <= 0.1) {
    final halfChord = math.sqrt(
      math.max(0, notchR * notchR - fabSink * fabSink),
    );
    final leftEdge = notchCX - halfChord;
    final rightEdge = notchCX + halfChord;

    notchCutout
      ..moveTo(leftEdge, 0)
      ..arcToPoint(
        Offset(rightEdge, 0),
        radius: Radius.circular(notchR),
        clockwise: false,
        largeArc: fabSink > 0,
      )
      ..close();
  } else {
    final distSq = math.pow(shoulder + notchR, 2) - math.pow(fabSink - shoulder, 2);
    final dx = math.sqrt(math.max(0, distSq as double));

    final xsLeft = notchCX - dx;
    final xsRight = notchCX + dx;
    final leftCenter = Offset(xsLeft, shoulder);
    final circleCenter = Offset(notchCX, fabSink);
    final dist = shoulder + notchR;
    final ratio = shoulder / dist;

    final p2Left = Offset(
      leftCenter.dx + (circleCenter.dx - leftCenter.dx) * ratio,
      leftCenter.dy + (circleCenter.dy - leftCenter.dy) * ratio,
    );
    final rightCenter = Offset(xsRight, shoulder);
    final p2Right = Offset(
      rightCenter.dx + (circleCenter.dx - rightCenter.dx) * ratio,
      rightCenter.dy + (circleCenter.dy - rightCenter.dy) * ratio,
    );

    notchCutout
      ..moveTo(xsLeft, 0)
      ..arcToPoint(
        p2Left,
        radius: Radius.circular(shoulder),
        clockwise: true,
      )
      ..arcToPoint(
        p2Right,
        radius: Radius.circular(notchR),
        clockwise: false,
        largeArc: shoulder < fabSink,
      )
      ..arcToPoint(
        Offset(xsRight, 0),
        radius: Radius.circular(shoulder),
        clockwise: true,
      )
      ..close();
  }

  return Path.combine(PathOperation.difference, barPath, notchCutout);
}

/// Paints the bottom navigation bar background with a smooth center notch.
class BottomNavNotchPainter extends CustomPainter {
  /// Creates a notch bar painter from resolved theme metrics.
  BottomNavNotchPainter({
    required this.theme,
    required this.barColor,
    required this.shadowColor,
    required this.notchCX,
    required this.notchR,
    required this.fabSink,
  });

  /// Visual configuration source.
  final BottomNavThemeData theme;

  /// Resolved bar fill color.
  final Color barColor;

  /// Resolved shadow color.
  final Color shadowColor;

  /// Horizontal center of the notch arc.
  final double notchCX;

  /// Notch arc radius (`fabSize / 2 + notchMargin`).
  final double notchR;

  /// Vertical center of the notch arc relative to the bar top.
  final double fabSink;

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildBottomNavBarPath(
      size: size,
      notchCX: notchCX,
      notchR: notchR,
      fabSink: fabSink,
      notchShoulderRadius: theme.notchShoulderRadius,
      cornerRadius: theme.cornerRadius,
    );

    final elevation = theme.elevation;
    if (elevation > 0) {
      canvas.drawPath(
        path.shift(Offset(0, -elevation * 0.15)),
        Paint()
          ..color = shadowColor
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, elevation * 0.6),
      );
    }

    canvas.drawPath(path, Paint()..color = barColor);
  }

  @override
  bool shouldRepaint(BottomNavNotchPainter oldDelegate) =>
      oldDelegate.theme != theme ||
      oldDelegate.barColor != barColor ||
      oldDelegate.shadowColor != shadowColor ||
      oldDelegate.notchCX != notchCX ||
      oldDelegate.notchR != notchR ||
      oldDelegate.fabSink != fabSink;
}
