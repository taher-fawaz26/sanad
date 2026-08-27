import 'package:app_animations/app_animations.dart';
import 'package:design_system/design_system.dart' show AppSwitch, AppTheme;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppSwitch].
@immutable
class SwitchStyleSpec {
  const SwitchStyleSpec({
    required this.trackWidth,
    required this.trackHeight,
    required this.knobSize,
    required this.knobInset,
    required this.trackRadius,
    required this.animationDuration,
    required this.offTrackColor,
    required this.onTrackColor,
    required this.enabledKnobColor,
    required this.disabledOffTrackColor,
    required this.disabledOffTrackBorderColor,
    required this.disabledOffKnobColor,
    required this.disabledOnTrackColor,
    required this.disabledOnKnobColor,
  });

  final double trackWidth;
  final double trackHeight;
  final double knobSize;
  final double knobInset;
  final BorderRadius trackRadius;
  final Duration animationDuration;

  final Color offTrackColor;
  final Color onTrackColor;
  final Color enabledKnobColor;
  final Color disabledOffTrackColor;
  final Color disabledOffTrackBorderColor;
  final Color disabledOffKnobColor;
  final Color disabledOnTrackColor;
  final Color disabledOnKnobColor;

  Color trackColor({required bool value, required bool enabled}) {
    if (!enabled) {
      return value ? disabledOnTrackColor : disabledOffTrackColor;
    }
    return value ? onTrackColor : offTrackColor;
  }

  Color knobColor({required bool value, required bool enabled}) {
    if (!enabled) {
      return value ? disabledOnKnobColor : disabledOffKnobColor;
    }
    return enabledKnobColor;
  }

  Border? trackBorder({required bool value, required bool enabled}) {
    if (enabled || value) {
      return null;
    }
    return Border.all(color: disabledOffTrackBorderColor);
  }
}

/// Theme extension registered in [AppTheme] for Figma switches.
@immutable
class AppSwitchTheme extends ThemeExtension<AppSwitchTheme> {
  const AppSwitchTheme({required this.spec});

  /// Figma `Controls / Switches` (`40:7496`) spec for the active brightness.
  final SwitchStyleSpec spec;

  @override
  AppSwitchTheme copyWith({SwitchStyleSpec? spec}) {
    return AppSwitchTheme(spec: spec ?? this.spec);
  }

  @override
  AppSwitchTheme lerp(covariant AppSwitchTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

/// Figma `Controls / Switches` (`40:7496`) token resolver.
abstract final class SwitchTokens {
  SwitchTokens._();

  static const double trackWidth = 56;
  static const double trackHeight = 32;
  static const double knobSize = 28;
  static const double knobInset = 2;
  static const Duration animationDuration = AppMotionDuration.quick;

  static AppSwitchTheme themeExtension({
    required AppColors colors,
    required Brightness brightness,
  }) {
    return AppSwitchTheme(
      spec: resolve(colors: colors, brightness: brightness),
    );
  }

  static SwitchStyleSpec resolve({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    return SwitchStyleSpec(
      trackWidth: responsiveDimension(trackWidth),
      trackHeight: responsiveDimension(trackHeight),
      knobSize: responsiveDimension(knobSize),
      knobInset: responsiveDimension(knobInset),
      trackRadius: BorderRadius.circular(responsiveDimension(trackHeight / 2)),
      animationDuration: animationDuration,
      offTrackColor: isDark
          ? colors.palettes.dark.shade600
          : colors.palettes.dark.shade200,
      onTrackColor: colors.primary,
      enabledKnobColor: colors.white,
      disabledOffTrackColor: colors.white,
      disabledOffTrackBorderColor: isDark
          ? colors.palettes.dark.shade800
          : colors.palettes.dark.shade200,
      disabledOffKnobColor: isDark
          ? colors.palettes.dark.shade800
          : colors.palettes.dark.shade200,
      disabledOnTrackColor: isDark
          ? colors.palettes.dark.shade900
          : colors.palettes.dark.shade200,
      disabledOnKnobColor: isDark
          ? colors.palettes.dark.shade800
          : colors.palettes.dark.shade100,
    );
  }
}
