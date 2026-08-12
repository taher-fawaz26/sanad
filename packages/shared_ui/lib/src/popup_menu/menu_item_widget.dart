import 'package:flutter/material.dart';
import 'package:shared_ui/src/popup_menu/menu_config.dart';
import 'package:shared_ui/src/popup_menu/menu_item.dart';

/// Renders a single [MenuItemProvider] inside a grid or list menu.
class MenuItemWidget extends StatefulWidget {
  /// Creates a menu item tile.
  const MenuItemWidget({
    required this.menuConfig,
    required this.item,
    this.showLine = false,
    this.clickCallback,
    super.key,
  });

  /// The entry rendered by this tile.
  final MenuItemProvider item;

  /// Shared menu configuration.
  final MenuConfig menuConfig;

  /// Whether to draw a trailing separator line (grid layout only).
  final bool showLine;

  /// Invoked when this tile is tapped.
  final void Function(MenuItemProvider item)? clickCallback;

  @override
  State<MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<MenuItemWidget> {
  late Color _color = widget.menuConfig.backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => setState(() {
        _color = widget.menuConfig.highlightColor;
      }),
      onTapUp: (details) => setState(() {
        _color = widget.menuConfig.backgroundColor;
      }),
      onLongPressEnd: (details) => setState(() {
        _color = widget.menuConfig.backgroundColor;
      }),
      onTap: () => widget.clickCallback?.call(widget.item),
      child: Container(
        width: widget.menuConfig.itemWidth,
        height: widget.menuConfig.itemHeight,
        decoration: BoxDecoration(
          color: _color,
          border: Border(
            right: BorderSide(
              color: widget.showLine
                  ? widget.menuConfig.lineColor
                  : Colors.transparent,
            ),
          ),
        ),
        child: _content(),
      ),
    );
  }

  Widget _content() {
    if (widget.item.menuImage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 30, height: 30, child: widget.item.menuImage),
          SizedBox(
            height: 22,
            child: Material(
              color: Colors.transparent,
              child: Text(
                widget.item.menuTitle,
                style: widget.item.menuTextStyle ?? widget.menuConfig.textStyle,
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Text(
          widget.item.menuTitle,
          style: widget.item.menuTextStyle ?? widget.menuConfig.textStyle,
          textAlign: widget.item.menuTextAlign ?? widget.menuConfig.textAlign,
        ),
      ),
    );
  }
}
