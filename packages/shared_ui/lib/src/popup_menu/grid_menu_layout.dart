import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_ui/src/popup_menu/menu_config.dart';
import 'package:shared_ui/src/popup_menu/menu_item.dart';
import 'package:shared_ui/src/popup_menu/menu_item_widget.dart';
import 'package:shared_ui/src/popup_menu/menu_layout.dart';
import 'package:shared_ui/src/popup_menu/popup_menu_overlay.dart';

/// Multi-column [PopupMenu] layout.
class GridMenuLayout implements MenuLayout {
  /// Creates a grid layout for [items].
  GridMenuLayout({
    required this.config,
    required this.items,
    required this.onDismiss,
    required this.context,
    this.onClickMenu,
  }) {
    _col = _calculateColCount();
    _row = _calculateRowCount();
  }

  /// Shared menu configuration.
  final MenuConfig config;

  /// Entries rendered by this layout.
  final List<MenuItemProvider> items;

  /// Invoked to close the menu after a tap.
  final VoidCallback onDismiss;

  /// The context the menu was shown from.
  final BuildContext context;

  /// Invoked when an entry is tapped, before [onDismiss].
  final MenuClickCallback? onClickMenu;

  int _row = 1;
  int _col = 1;

  double _menuWidth() => config.itemWidth * _col;

  double _menuHeight() => config.itemHeight * _row;

  List<Widget> _createRows() {
    return [
      for (var i = 0; i < _row; i++)
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: (i < _row - 1 && _row != 1)
                    ? config.lineColor
                    : Colors.transparent,
              ),
            ),
          ),
          height: config.itemHeight,
          child: Row(children: _createRowItems(i)),
        ),
    ];
  }

  List<Widget> _createRowItems(int row) {
    final subItems = items.sublist(
      row * _col,
      min(row * _col + _col, items.length),
    );
    return [
      for (var i = 0; i < subItems.length; i++)
        _createMenuItem(subItems[i], i < (_col - 1)),
    ];
  }

  int _calculateRowCount() {
    if (items.isEmpty) return 0;
    if (_calculateColCount() == 1) return items.length;
    return (items.length - 1) ~/ _calculateColCount() + 1;
  }

  int _calculateColCount() {
    assert(items.isNotEmpty, 'error: menu items can not be null');
    final itemCount = items.length;
    if (config.maxColumn != 4 && config.maxColumn > 0) return config.maxColumn;
    // 4 items render as a 2x2 grid rather than a single row.
    if (itemCount == 4) return 2;
    if (itemCount <= config.maxColumn) return itemCount;
    if (itemCount == 5 || itemCount == 6) return 3;
    return config.maxColumn;
  }

  Widget _createMenuItem(MenuItemProvider item, bool showLine) {
    return MenuItemWidget(
      menuConfig: config,
      item: item,
      showLine: showLine,
      clickCallback: _itemClicked,
    );
  }

  void _itemClicked(MenuItemProvider item) {
    onClickMenu?.call(item);
    onDismiss();
  }

  @override
  Widget build() {
    return SizedBox(
      width: _menuWidth(),
      height: _menuHeight(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: _createRows()),
        ),
      ),
    );
  }

  @override
  double get height => _menuHeight();

  @override
  double get width => _menuWidth();
}
