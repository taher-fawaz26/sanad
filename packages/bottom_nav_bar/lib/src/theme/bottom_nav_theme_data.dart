import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Visual and layout configuration for bottom navigation widgets.
@immutable
class BottomNavThemeData {
  /// Creates bottom navigation theme data.
  const BottomNavThemeData({
    this.barHeight = 72,
    this.fabSize = 52,
    this.cornerRadius = 24,
    this.notchMargin = 8,
    this.horizontalInset = 16,
    this.bottomInset = 8,
    this.contentPadding = 12,
    this.centerGap = 72,
    this.iconSize = 24,
    this.elevation = 8,
    this.fanDistance = 72,
    this.fanAngle = 180,
    this.animationDuration = const Duration(milliseconds: 250),
    this.barColor,
    this.shadowColor,
    this.selectedColor,
    this.unselectedColor,
    this.fabBackgroundColor,
    this.fabForegroundColor,
    this.labelStyle,
    this.selectedLabelStyle,
  });

  /// Height of the bottom bar (excluding FAB protrusion).
  final double barHeight;

  /// Diameter of the center control.
  final double fabSize;

  /// Corner radius of the floating bar container.
  final double cornerRadius;

  /// Gap between FAB and notch edge.
  final double notchMargin;

  /// Horizontal margin outside the bar.
  final double horizontalInset;

  /// Bottom margin outside the bar.
  final double bottomInset;

  /// Horizontal padding inside the bar.
  final double contentPadding;

  /// Width reserved for the center FAB notch gap.
  final double centerGap;

  /// Icon size for destinations and actions.
  final double iconSize;

  /// Elevation of the bar container.
  final double elevation;

  /// Distance of fan actions from the center control.
  final double fanDistance;

  /// Fan spread angle in degrees.
  final double fanAngle;

  /// Default animation duration.
  final Duration animationDuration;

  /// Bar background; falls back to [ColorScheme.surface].
  final Color? barColor;

  /// Bar shadow color.
  final Color? shadowColor;

  /// Selected destination color; falls back to [ColorScheme.primary].
  final Color? selectedColor;

  /// Unselected destination color; falls back to [ColorScheme.onSurfaceVariant].
  final Color? unselectedColor;

  /// Center control background; falls back to [ColorScheme.primary].
  final Color? fabBackgroundColor;

  /// Center control foreground; falls back to [ColorScheme.onPrimary].
  final Color? fabForegroundColor;

  /// Label style for unselected destinations.
  final TextStyle? labelStyle;

  /// Label style for selected destinations.
  final TextStyle? selectedLabelStyle;

  /// Resolves [barColor] using Material [Theme] when unset.
  Color resolveBarColor(BuildContext context) =>
      barColor ?? Theme.of(context).colorScheme.surface;

  /// Resolves [shadowColor] using Material [Theme] when unset.
  Color resolveShadowColor(BuildContext context) =>
      shadowColor ?? Theme.of(context).shadowColor;

  /// Resolves [selectedColor] using Material [Theme] when unset.
  Color resolveSelectedColor(BuildContext context) =>
      selectedColor ?? Theme.of(context).colorScheme.primary;

  /// Resolves [unselectedColor] using Material [Theme] when unset.
  Color resolveUnselectedColor(BuildContext context) =>
      unselectedColor ?? Theme.of(context).colorScheme.onSurfaceVariant;

  /// Resolves [fabBackgroundColor] using Material [Theme] when unset.
  Color resolveFabBackgroundColor(BuildContext context) =>
      fabBackgroundColor ?? Theme.of(context).colorScheme.primary;

  /// Resolves [fabForegroundColor] using Material [Theme] when unset.
  Color resolveFabForegroundColor(BuildContext context) =>
      fabForegroundColor ?? Theme.of(context).colorScheme.onPrimary;

  /// Resolves destination label style for the given selection state.
  TextStyle resolveLabelStyle(BuildContext context, {required bool selected}) {
    final base = Theme.of(context).textTheme.labelSmall;
    final resolved = selected
        ? (selectedLabelStyle ?? labelStyle ?? base)
        : (labelStyle ?? base);
    final color = selected
        ? resolveSelectedColor(context)
        : resolveUnselectedColor(context);
    return (resolved ?? const TextStyle(fontSize: 12)).copyWith(
      fontWeight: selected ? FontWeight.w500 : FontWeight.w500,
      color: color,
      height: 16 / 12,
    );
  }

  /// Returns a copy with the given fields replaced.
  BottomNavThemeData copyWith({
    double? barHeight,
    double? fabSize,
    double? cornerRadius,
    double? notchMargin,
    double? horizontalInset,
    double? bottomInset,
    double? contentPadding,
    double? centerGap,
    double? iconSize,
    double? elevation,
    double? fanDistance,
    double? fanAngle,
    Duration? animationDuration,
    Color? barColor,
    Color? shadowColor,
    Color? selectedColor,
    Color? unselectedColor,
    Color? fabBackgroundColor,
    Color? fabForegroundColor,
    TextStyle? labelStyle,
    TextStyle? selectedLabelStyle,
  }) {
    return BottomNavThemeData(
      barHeight: barHeight ?? this.barHeight,
      fabSize: fabSize ?? this.fabSize,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      notchMargin: notchMargin ?? this.notchMargin,
      horizontalInset: horizontalInset ?? this.horizontalInset,
      bottomInset: bottomInset ?? this.bottomInset,
      contentPadding: contentPadding ?? this.contentPadding,
      centerGap: centerGap ?? this.centerGap,
      iconSize: iconSize ?? this.iconSize,
      elevation: elevation ?? this.elevation,
      fanDistance: fanDistance ?? this.fanDistance,
      fanAngle: fanAngle ?? this.fanAngle,
      animationDuration: animationDuration ?? this.animationDuration,
      barColor: barColor ?? this.barColor,
      shadowColor: shadowColor ?? this.shadowColor,
      selectedColor: selectedColor ?? this.selectedColor,
      unselectedColor: unselectedColor ?? this.unselectedColor,
      fabBackgroundColor: fabBackgroundColor ?? this.fabBackgroundColor,
      fabForegroundColor: fabForegroundColor ?? this.fabForegroundColor,
      labelStyle: labelStyle ?? this.labelStyle,
      selectedLabelStyle: selectedLabelStyle ?? this.selectedLabelStyle,
    );
  }
}
