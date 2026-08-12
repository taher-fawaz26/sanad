import 'package:flutter/material.dart';

/// Contract for an entry rendered by [PopupMenu] — implement this directly
/// for custom item types, or use the default [MenuItem].
abstract class MenuItemProvider {
  /// The label shown for this entry.
  String get menuTitle;

  /// Arbitrary payload attached to this entry, returned by the menu's click
  /// callback.
  dynamic get menuUserInfo;

  /// Leading visual (icon/image) shown above or beside the title.
  Widget? get menuImage;

  /// Overrides [MenuConfig.textStyle] for this entry when set.
  TextStyle? get menuTextStyle;

  /// Overrides [MenuConfig.textAlign] for this entry when set.
  TextAlign? get menuTextAlign;
}

/// Default [MenuItemProvider] implementation.
class MenuItem extends MenuItemProvider {
  /// Creates a menu item.
  MenuItem({
    this.title = '',
    this.image,
    this.userInfo,
    this.textStyle,
    this.textAlign = TextAlign.center,
  });

  /// Creates a menu item pre-configured for [MenuType.list] (left-aligned
  /// text, dark-on-light default style).
  factory MenuItem.forList({
    required String title,
    Widget? image,
    dynamic userInfo,
    TextStyle textStyle = const TextStyle(
      color: Color(0xFF181818),
      fontSize: 10,
    ),
    TextAlign textAlign = TextAlign.center,
  }) {
    return MenuItem(
      title: title,
      image: image,
      userInfo: userInfo,
      textAlign: textAlign,
      textStyle: textStyle,
    );
  }

  /// Leading visual for this entry.
  final Widget? image;

  /// The label shown for this entry.
  final String title;

  /// Arbitrary payload attached to this entry.
  final dynamic userInfo;

  /// Overrides the menu's default text style for this entry.
  final TextStyle? textStyle;

  /// Overrides the menu's default text alignment for this entry.
  final TextAlign? textAlign;

  @override
  Widget? get menuImage => image;

  @override
  String get menuTitle => title;

  @override
  dynamic get menuUserInfo => userInfo;

  @override
  TextStyle? get menuTextStyle => textStyle;

  @override
  TextAlign? get menuTextAlign => textAlign;
}
