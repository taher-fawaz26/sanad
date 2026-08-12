import 'package:flutter/material.dart';
import 'package:shared_ui/src/popup_menu/popup_menu_overlay.dart';

/// Visual and layout configuration for [PopupMenu].
@immutable
class MenuConfig {
  /// Creates menu configuration.
  const MenuConfig({
    this.type = MenuType.grid,
    this.itemWidth = 72.0,
    this.itemHeight = 65.0,
    this.arrowHeight = 10.0,
    this.maxColumn = 4,
    this.backgroundColor = const Color(0xff232323),
    this.highlightColor = const Color(0xff353535),
    this.lineColor = const Color(0x55000000),
    this.textStyle = const TextStyle(color: Color(0xffc5c5c5), fontSize: 10),
    this.textAlign = TextAlign.center,
  });

  /// Creates configuration pre-tuned for [MenuType.list].
  factory MenuConfig.forList({
    double itemWidth = 120.0,
    double itemHeight = 40.0,
    double arrowHeight = 10.0,
    Color backgroundColor = Colors.white,
    Color highlightColor = const Color(0xff353535),
    Color lineColor = const Color(0x55000000),
  }) {
    return MenuConfig(
      type: MenuType.list,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      arrowHeight: arrowHeight,
      backgroundColor: backgroundColor,
      highlightColor: highlightColor,
      lineColor: lineColor,
    );
  }

  /// Grid (multi-column) or list (single-column) layout.
  final MenuType type;

  /// Width of each menu item (and the list menu's total width).
  final double itemWidth;

  /// Height of each menu item.
  final double itemHeight;

  /// Height of the pointer triangle connecting the menu to its anchor.
  final double arrowHeight;

  /// Maximum number of columns for [MenuType.grid].
  final int maxColumn;

  /// Menu background color.
  final Color backgroundColor;

  /// Item background color while pressed.
  final Color highlightColor;

  /// Separator line color between grid items.
  final Color lineColor;

  /// Default text style, overridable per [MenuItemProvider].
  final TextStyle textStyle;

  /// Default text alignment for [MenuType.list], overridable per
  /// [MenuItemProvider].
  final TextAlign textAlign;
}
