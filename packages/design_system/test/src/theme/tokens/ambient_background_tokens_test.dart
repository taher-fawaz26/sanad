import 'dart:math' as math;

import 'package:design_system/src/theme/colors/light_colors.dart';
import 'package:design_system/src/theme/tokens/ambient_background_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared page wash — Figma
/// `linear-gradient(203.89deg, #F9F9FA 59.275%, #C9FBD8 97.118%)`.
///
/// Worth pinning in a test because the failure mode is silent: a gradient that
/// is a few degrees or a few percent off still renders, still looks like a
/// gradient, and only reads as wrong beside the design.
void main() {
  const colors = LightColors.colors;

  LinearGradient gradientFor(
    Size size, {
    TextDirection direction = TextDirection.ltr,
  }) => AmbientBackgroundTokens.gradient(
    colors: colors,
    size: size,
    direction: direction,
  );

  group('the Figma spec', () {
    test('carries Figma stops and colours', () {
      final gradient = gradientFor(const Size(390, 844));

      expect(gradient.stops, [0.59275, 0.97118]);
      expect(gradient.colors.first, colors.background);
      expect(gradient.colors.last, const Color(0xFFC9FBD8));
    });

    test(
      'the near-white end is the theme background, not a second literal',
      () {
        // Two spellings of `#F9F9FA` is how the page and its wash drift apart.
        expect(AmbientBackgroundTokens.clear(colors), colors.background);
        expect(colors.background, const Color(0xFFF9F9FA));
      },
    );
  });

  group('the axis reproduces the CSS angle', () {
    test('on the design frame it runs top-trailing to bottom-leading', () {
      final gradient = gradientFor(const Size(390, 844));

      // Solved from 203.89°: down and toward the leading edge. The magnitudes
      // exceed 1 on the vertical because CSS sizes the gradient line so the
      // end stops land on the corners the angle points at, which is longer
      // than the box is tall.
      expect(gradient.begin, isA<Alignment>());
      final begin = gradient.begin as Alignment;
      final end = gradient.end as Alignment;
      expect(begin.x, closeTo(0.9654, 0.001));
      expect(begin.y, closeTo(-1.0071, 0.001));
      expect(end.x, closeTo(-0.9654, 0.001));
      expect(end.y, closeTo(1.0071, 0.001));
    });

    test('the same angle holds whatever shape the box is', () {
      // The bug this replaces: fixed `topRight → bottomLeft` alignments track
      // the box's *diagonal*, so the wash tilted with the box. Here the angle
      // in pixel space is constant — which means the alignment components
      // must move in opposite directions as the box changes shape, since they
      // are normalized by width and height separately.
      const expected = AmbientBackgroundTokens.angleDegrees;

      for (final size in [
        const Size(390, 844),
        const Size(360, 800),
        const Size(390, 300),
        const Size(1024, 768),
      ]) {
        final gradient = gradientFor(size);
        final begin = gradient.begin as Alignment;
        final end = gradient.end as Alignment;

        // Alignment units span -1..1 across the box, so a component maps to
        // pixels by half the corresponding side.
        final dxPixels = (end.x - begin.x) * size.width / 2;
        final dyPixels = (end.y - begin.y) * size.height / 2;

        // CSS: 0° points at the top and the angle grows clockwise, so the
        // screen-space direction is `(sin θ, -cos θ)`.
        final degrees =
            (math.atan2(dxPixels, -dyPixels) * 180 / math.pi + 360) % 360;
        expect(degrees, closeTo(expected, 0.001), reason: '$size');

        // ...and the axis is as long as the CSS gradient line, which is what
        // makes 59.275% mean what Figma means by it.
        final length = math.sqrt(dxPixels * dxPixels + dyPixels * dyPixels);
        final cssLength =
            size.width * math.sin(expected * math.pi / 180).abs() +
            size.height * math.cos(expected * math.pi / 180).abs();
        expect(length, closeTo(cssLength, 0.001), reason: '$size');
      }
    });

    test('it mirrors under RTL', () {
      final ltr = gradientFor(const Size(390, 844)).begin as Alignment;
      final rtl =
          gradientFor(const Size(390, 844), direction: TextDirection.rtl).begin
              as Alignment;

      expect(rtl.x, closeTo(-ltr.x, 0.0001));
      // Only the horizontal mirrors: the wash still runs downward.
      expect(rtl.y, closeTo(ltr.y, 0.0001));
    });
  });

  group('degenerate boxes', () {
    // A background is routinely laid out before anything has constrained it,
    // and `Alignment(NaN, NaN)` is a crash, not a colour.
    for (final size in [Size.zero, const Size(0, 844), Size.infinite]) {
      test('$size falls back to the leading diagonal', () {
        final gradient = gradientFor(size);
        final begin = gradient.begin as Alignment;
        final end = gradient.end as Alignment;

        expect(begin, const Alignment(1, -1));
        expect(end, const Alignment(-1, 1));
      });
    }

    test('the fallback mirrors under RTL too', () {
      final gradient = gradientFor(Size.zero, direction: TextDirection.rtl);

      expect(gradient.begin, const Alignment(-1, -1));
      expect(gradient.end, const Alignment(1, 1));
    });
  });
}
