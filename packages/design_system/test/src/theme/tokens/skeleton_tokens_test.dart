import 'package:design_system/src/theme/colors/dark_colors.dart';
import 'package:design_system/src/theme/colors/light_colors.dart';
import 'package:design_system/src/theme/tokens/skeleton_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Perceived lightness, 0 (black) – 1 (white). Cheap proxy for "does this
/// look like a light, low-contrast skeleton" without a brittle exact-hex
/// snapshot.
double _lightness(Color color) => color.computeLuminance();

void main() {
  group('SkeletonTokens — light theme', () {
    const colors = LightColors.colors;

    test('base/highlight/container are all light, low-contrast neutrals', () {
      // Regression guard for the "dark charcoal skeleton card" bug: every
      // resolved color must read as light, not a near-black surface.
      expect(
        _lightness(SkeletonTokens.resolveBaseColor(colors)),
        greaterThan(0.5),
      );
      expect(
        _lightness(SkeletonTokens.resolveHighlightColor(colors)),
        greaterThan(0.5),
      );
      expect(
        _lightness(SkeletonTokens.resolveContainersColor(colors)),
        greaterThan(0.5),
      );
    });

    test('containers color is never the near-black onBackground token', () {
      // The regression this test guards against: containersColor used to be
      // `colors.onBackground`, which painted every skeleton card near-black.
      expect(
        SkeletonTokens.resolveContainersColor(colors),
        isNot(colors.onBackground),
      );
      expect(_lightness(colors.onBackground), lessThan(0.2));
    });

    test('highlight is not pure white (keeps the sweep low-contrast)', () {
      expect(SkeletonTokens.resolveHighlightColor(colors), isNot(Colors.white));
    });

    test('container fill sits between the base and highlight lightness', () {
      final baseLightness = _lightness(SkeletonTokens.resolveBaseColor(colors));
      final highlightLightness = _lightness(
        SkeletonTokens.resolveHighlightColor(colors),
      );
      final containerLightness = _lightness(
        SkeletonTokens.resolveContainersColor(colors),
      );
      expect(
        containerLightness,
        inInclusiveRange(baseLightness, highlightLightness),
      );
    });
  });

  group('SkeletonTokens — dark theme stays theme-relative', () {
    const colors = DarkColors.colors;

    test('base/highlight/container are all dark, matching a dark page', () {
      // Colors are derived from the theme's own disabled/background tokens,
      // so switching to DarkColors must flip them dark too — never a light
      // skeleton box stranded on a dark page.
      expect(
        _lightness(SkeletonTokens.resolveBaseColor(colors)),
        lessThan(0.5),
      );
      expect(
        _lightness(SkeletonTokens.resolveHighlightColor(colors)),
        lessThan(0.5),
      );
      expect(
        _lightness(SkeletonTokens.resolveContainersColor(colors)),
        lessThan(0.5),
      );
    });
  });
}
