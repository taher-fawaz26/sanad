import 'package:bottom_nav_bar/src/controller/bottom_nav_controller.dart';
import 'package:bottom_nav_bar/src/expandable/circular_menu_adapter.dart';
import 'package:bottom_nav_bar/src/models/bottom_nav_action.dart';
import 'package:bottom_nav_bar/src/theme/bottom_nav_theme_data.dart';
import 'package:bottom_nav_bar/src/typedefs.dart';
import 'package:bottom_nav_bar/src/widgets/bottom_nav_center_face.dart';
import 'package:bottom_nav_bar/src/widgets/circular_menu.dart';
import 'package:bottom_nav_bar/src/widgets/circular_menu_item.dart';
import 'package:flutter/material.dart';

/// Center expandable navigation control.
class BottomNavExpandableCenter<T> extends StatefulWidget {
  /// Creates a center expandable control.
  const BottomNavExpandableCenter({
    required this.actions,
    required this.selectedItem,
    required this.onActionSelected,
    required this.controller,
    required this.theme,
    this.fabBuilder,
    super.key,
  });

  /// Expandable center actions.
  final List<BottomNavAction<T>> actions;

  /// Currently selected navigation item (destination or action).
  final T? selectedItem;

  /// Called when a center action is tapped.
  final ValueChanged<T> onActionSelected;

  /// UI state for expand / collapse.
  final BottomNavController controller;

  /// Visual configuration.
  final BottomNavThemeData theme;

  /// Optional custom center face builder.
  final BottomNavFabBuilder<T>? fabBuilder;

  /// Scaffold FAB location required by this widget.
  static FloatingActionButtonLocation get fabLocation =>
      FloatingActionButtonLocation.centerDocked;

  @override
  State<BottomNavExpandableCenter<T>> createState() =>
      _BottomNavExpandableCenterState<T>();
}

class _BottomNavExpandableCenterState<T>
    extends State<BottomNavExpandableCenter<T>> {
  final GlobalKey<CircularMenuState> _menuKey = GlobalKey<CircularMenuState>();
  late final CircularMenuAdapter _adapter;

  @override
  void initState() {
    super.initState();
    _adapter = CircularMenuAdapter(_menuKey);
    bindBottomNavExpandable(widget.controller, _adapter);
  }

  @override
  void didUpdateWidget(covariant BottomNavExpandableCenter<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      unbindBottomNavExpandable(oldWidget.controller);
      bindBottomNavExpandable(widget.controller, _adapter);
    }
  }

  @override
  void dispose() {
    unbindBottomNavExpandable(widget.controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final fabColor = theme.resolveFabBackgroundColor(context);
    final fabForeground = theme.resolveFabForegroundColor(context);
    final fabPadding = (theme.fabSize - theme.iconSize) / 2;
    final fabShadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];

    return SizedBox(
      width: theme.fanDistance * 2 + theme.fabSize,
      height: theme.fanDistance + theme.fabSize,
      child: CircularMenu(
        key: _menuKey,
        alignment: Alignment.bottomCenter,
        radius: theme.fanDistance,
        animationDuration: theme.animationDuration,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
        toggleButtonColor: fabColor,
        toggleButtonSize: theme.iconSize,
        toggleButtonPadding: fabPadding,
        toggleButtonMargin: 0,
        toggleButtonIconColor: fabForeground,
        toggleButtonBoxShadow: fabShadow,
        toggleButtonChild: _buildClosedFace(context),
        onOpen: () => notifyBottomNavOpened(widget.controller),
        onClose: () => notifyBottomNavClosed(widget.controller),
        items: [
          for (final action in widget.actions)
            CircularMenuItem(
              onTap: () {
                widget.controller.collapse();
                widget.onActionSelected(action.item);
              },
              color: fabColor,
              padding: fabPadding,
              margin: 0,
              iconSize: theme.iconSize,
              boxShadow: fabShadow,
              semanticLabel: action.semanticLabel ?? action.label,
              child: action.iconBuilder(context, selected: true),
            ),
        ],
      ),
    );
  }

  Widget _buildClosedFace(BuildContext context) {
    final builder = widget.fabBuilder;
    if (builder != null) {
      return builder(
        context,
        selectedItem: widget.selectedItem,
        isExpanded: widget.controller.expanded,
        onPressed: widget.controller.toggle,
        theme: widget.theme,
        actions: widget.actions,
      );
    }

    return BottomNavCenterFace<T>(
      selectedItem: widget.selectedItem,
      actions: widget.actions,
      theme: widget.theme,
    );
  }
}
