import 'package:flutter/widgets.dart';

/// A wrapper for [IconData] to ensure type safety and correct rendering
/// with [FaIcon].
///
/// This class prevents usage of Font Awesome icons in the standard [Icon] widget,
/// which would result in incorrect rendering (clipping/misalignment) for
/// non-square icons.
@immutable
final class FaIconData {
  /// The underlying [IconData] for this font awesome icon.
  final IconData data;

  /// Creates a wrapper for the given [data].
  const FaIconData(this.data);

  /// The code point of the icon.
  int get codePoint => data.codePoint;

  /// The font family of the icon.
  String? get fontFamily => data.fontFamily;

  /// The font package of the icon.
  String? get fontPackage => data.fontPackage;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FaIconData && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'FaIconData(data: $data)';
}

/// [FaIconData] for a font awesome duotone icon.
///
/// Duotone icons consist of a primary and a secondary layer.
@immutable
final class FaDuotoneIconData {
  /// The primary layer of the icon.
  final IconData primary;

  /// The secondary layer of the icon.
  final IconData secondary;

  /// Creates a duotone icon data.
  const FaDuotoneIconData({required this.primary, required this.secondary});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FaDuotoneIconData &&
        other.primary == primary &&
        other.secondary == secondary;
  }

  @override
  int get hashCode => Object.hash(primary, secondary);

  @override
  String toString() =>
      'FaDuotoneIconData(primary: $primary, secondary: $secondary)';
}
