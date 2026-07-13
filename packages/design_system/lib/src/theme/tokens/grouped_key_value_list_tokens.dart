import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/key_value_card_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// One row inside [AppGroupedKeyValueList].
class GroupedKeyValueItem {
  const GroupedKeyValueItem({
    required this.title,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  final String title;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
}

/// Resolved styling for [AppGroupedKeyValueList].
@immutable
class GroupedKeyValueListStyleSpec {
  const GroupedKeyValueListStyleSpec({
    required this.borderRadius,
    required this.backgroundColor,
    required this.borderColor,
    required this.dividerColor,
    required this.rowHeight,
    required this.horizontalPadding,
    required this.titleStyle,
    required this.valueStyle,
  });

  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final Color dividerColor;
  final double rowHeight;
  final double horizontalPadding;
  final TextStyle titleStyle;
  final TextStyle valueStyle;
}

/// Figma grouped schedule/contact rows (`365:14910`) token resolver.
abstract final class GroupedKeyValueListTokens {
  GroupedKeyValueListTokens._();

  static GroupedKeyValueListStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final rowSpec = KeyValueCardTokens.resolve(
      colors: colors,
      typography: typography,
      brightness: brightness,
    );
    final sky = colors.palettes.sky;
    final isDark = brightness == Brightness.dark;

    return GroupedKeyValueListStyleSpec(
      borderRadius: rowSpec.borderRadius,
      backgroundColor: rowSpec.backgroundColor,
      borderColor: rowSpec.borderColor,
      dividerColor: isDark ? sky.shade700 : sky.shade200,
      rowHeight: rowSpec.height,
      horizontalPadding: rowSpec.horizontalPadding,
      titleStyle: rowSpec.titleStyle,
      valueStyle: rowSpec.valueStyle,
    );
  }
}
