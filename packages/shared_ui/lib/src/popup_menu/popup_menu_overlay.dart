import 'package:flutter/material.dart';
import 'package:shared_ui/src/popup_menu/grid_menu_layout.dart';
import 'package:shared_ui/src/popup_menu/list_menu_layout.dart';
import 'package:shared_ui/src/popup_menu/menu_config.dart';
import 'package:shared_ui/src/popup_menu/menu_item.dart';
import 'package:shared_ui/src/popup_menu/menu_layout.dart';
import 'package:shared_ui/src/popup_menu/popup_menu_utils.dart';
import 'package:shared_ui/src/popup_menu/triangle_painter.dart';

/// Layout of a [PopupMenu]'s entries.
enum MenuType {
  /// Multi-column grid of icon+label tiles.
  grid,

  /// Single-column list of rows.
  list,
}

/// Invoked when a [PopupMenu] entry is tapped.
typedef MenuClickCallback = void Function(MenuItemProvider item);

/// A small popover menu — pointing at an anchor widget or [Rect] via a
/// triangle indicator — shown above an [Overlay].
///
/// Attach the menu to a widget with a [GlobalKey]:
/// ```dart
/// final menu = PopupMenu(
///   context: context,
///   items: [MenuItem(title: 'Copy'), MenuItem(title: 'Paste')],
///   onClickMenu: (item) => print(item.menuTitle),
/// );
/// menu.show(widgetKey: anchorKey);
/// ```
class PopupMenu {
  /// Creates a popup menu. Call [show] to display it.
  PopupMenu({
    required this.context,
    required this.items,
    this.config = const MenuConfig(),
    this.onClickMenu,
    this.onDismiss,
    this.onShow,
  });

  /// The context the menu is shown from — must have an [Overlay] ancestor.
  final BuildContext context;

  /// Entries rendered by the menu.
  final List<MenuItemProvider> items;

  /// Layout and visual configuration.
  final MenuConfig config;

  /// Invoked when an entry is tapped.
  final MenuClickCallback? onClickMenu;

  /// Invoked after the menu is dismissed (tap-away, drag, or entry tap).
  final VoidCallback? onDismiss;

  /// Invoked right after the menu is inserted into the [Overlay].
  final VoidCallback? onShow;

  OverlayEntry? _entry;
  MenuLayout? _menuLayout;
  bool _isShow = false;

  /// Whether the menu is currently shown.
  bool get isShow => _isShow;

  /// Shows the menu anchored to [rect], or to the widget registered under
  /// [widgetKey]. Exactly one of the two must be provided.
  void show({Rect? rect, GlobalKey? widgetKey}) {
    assert(
      rect != null || widgetKey != null,
      "'rect' and 'widgetKey' can't be both null",
    );

    final attachRect = rect ?? getWidgetGlobalRect(widgetKey!);

    _menuLayout = switch (config.type) {
      MenuType.grid => GridMenuLayout(
        config: config,
        items: items,
        onDismiss: dismiss,
        context: context,
        onClickMenu: onClickMenu,
      ),
      MenuType.list => ListMenuLayout(
        config: config,
        items: items,
        onDismiss: dismiss,
        context: context,
        onClickMenu: onClickMenu,
      ),
    };

    final layout = _calculateOffset(
      context,
      attachRect,
      _menuLayout!.width,
      _menuLayout!.height,
    );

    _entry = OverlayEntry(builder: (context) => _build(layout, _menuLayout!));
    Overlay.of(context).insert(_entry!);
    _isShow = true;
    onShow?.call();
  }

  Widget _build(_LayoutPosition layout, MenuLayout menu) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: dismiss,
      onVerticalDragStart: (details) => dismiss(),
      onHorizontalDragStart: (details) => dismiss(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned(
              left:
                  layout.attachRect.left + layout.attachRect.width / 2.0 - 7.5,
              top: layout.isDown
                  ? layout.offset.dy + layout.height
                  : layout.offset.dy - config.arrowHeight,
              child: CustomPaint(
                size: Size(15, config.arrowHeight),
                painter: TrianglePainter(
                  isDown: layout.isDown,
                  color: config.backgroundColor,
                ),
              ),
            ),
            Positioned(
              left: layout.offset.dx,
              top: layout.offset.dy,
              child: menu.build(),
            ),
          ],
        ),
      ),
    );
  }

  _LayoutPosition _calculateOffset(
    BuildContext context,
    Rect attachRect,
    double contentWidth,
    double contentHeight,
  ) {
    final screenSize = MediaQuery.sizeOf(context);

    var dx = attachRect.left + attachRect.width / 2.0 - contentWidth / 2.0;
    if (dx < 10.0) dx = 10.0;
    if (dx + contentWidth > screenSize.width && dx > 10.0) {
      final tempDx = screenSize.width - contentWidth - 10;
      if (tempDx > 10) dx = tempDx;
    }

    var dy = attachRect.top - contentHeight;
    var isDown = false;
    if (dy <= MediaQuery.paddingOf(context).top + 10) {
      // Not enough space above the anchor — show the menu below it instead.
      dy = config.arrowHeight + attachRect.height + attachRect.top;
      isDown = false;
    } else {
      dy -= config.arrowHeight;
      isDown = true;
    }

    return _LayoutPosition(
      width: contentWidth,
      height: contentHeight,
      attachRect: attachRect,
      offset: Offset(dx, dy),
      isDown: isDown,
    );
  }

  /// Dismisses the menu, if shown.
  void dismiss() {
    if (!_isShow) return;
    _entry?.remove();
    _isShow = false;
    onDismiss?.call();
  }
}

class _LayoutPosition {
  const _LayoutPosition({
    required this.width,
    required this.height,
    required this.offset,
    required this.attachRect,
    required this.isDown,
  });

  final double width;
  final double height;
  final Offset offset;
  final Rect attachRect;
  final bool isDown;
}
