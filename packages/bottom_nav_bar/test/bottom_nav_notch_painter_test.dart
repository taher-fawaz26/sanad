import 'package:bottom_nav_bar/src/theme/bottom_nav_theme_data.dart';
import 'package:bottom_nav_bar/src/widgets/bottom_nav_notch_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildBottomNavBarPath', () {
    const size = Size(360, 72);
    const notchCX = 180.0;
    const notchR = 34.0;
    const fabSink = 26.0;

    test('shoulder mode produces non-empty bounded path', () {
      final path = buildBottomNavBarPath(
        size: size,
        notchCX: notchCX,
        notchR: notchR,
        fabSink: fabSink,
        notchShoulderRadius: 12,
        cornerRadius: 24,
      );

      expect(path.getBounds().isEmpty, isFalse);
      expect(path.getBounds().width, closeTo(size.width, 1));
      expect(path.getBounds().height, closeTo(size.height, 1));
    });

    test('semicircle mode produces non-empty path when shoulder is zero', () {
      final path = buildBottomNavBarPath(
        size: size,
        notchCX: notchCX,
        notchR: notchR,
        fabSink: fabSink,
        notchShoulderRadius: 0,
        cornerRadius: 24,
      );

      expect(path.getBounds().isEmpty, isFalse);
    });
  });

  group('BottomNavThemeData notch metrics', () {
    test('notchRadius derives from fabSize and notchMargin', () {
      const theme = BottomNavThemeData(fabSize: 52, notchMargin: 8);

      expect(theme.notchRadius, 34);
      expect(theme.resolveFabSink(), 26);
    });
  });
}
