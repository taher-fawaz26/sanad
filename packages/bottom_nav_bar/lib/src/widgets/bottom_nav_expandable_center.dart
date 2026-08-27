import 'package:app_animations/app_animations.dart';
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
    final fabClosedColor = theme.resolveFabBackgroundColor(context);
    final fabOpenColor = theme.resolveFabOpenBackgroundColor(context);
    final fabPadding = (theme.fabSize - theme.iconSize) / 2;

    return ListenableBuilder(
      listenable: widget.controller.isExpanded,
      builder: (context, _) {
        final expanded = widget.controller.expanded;
        final menuWidth = expanded
            ? theme.fanDistance * 3 + theme.fabSize
            : theme.fabSize * 1.3;
        final menuHeight = expanded
            ? theme.fanDistance * 0 + theme.fabSize * .8
            : theme.fabSize * 1.25;
        final fabShadow = _buildFabShadows(context, expanded: expanded);

        return SizedBox(
          width: menuWidth,
          height: menuHeight,
          child: CircularMenu(
            key: _menuKey,
            alignment: Alignment.bottomCenter,
            radius: theme.fanDistance,
            animationDuration: theme.animationDuration,
            curve: AppMotionCurve.decelerated,
            reverseCurve: AppMotionCurve.accelerated,
            toggleButtonColor: fabClosedColor,
            toggleButtonOpenColor: fabOpenColor,
            toggleButtonSize: theme.iconSize,
            toggleButtonPadding: fabPadding,
            toggleButtonMargin: 0,
            toggleButtonBoxShadow: fabShadow,
            toggleButtonChild: _buildToggleFace(context, isExpanded: false),
            toggleButtonOpenChild: _buildToggleFace(context, isExpanded: true),
            onOpen: () => notifyBottomNavOpened(widget.controller),
            onClose: () => notifyBottomNavClosed(widget.controller),
            items: [
              for (final action in widget.actions)
                CircularMenuItem(
                  onTap: () {
                    widget.controller.collapse();
                    widget.onActionSelected(action.item);
                  },
                  color: fabClosedColor,
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
      },
    );
  }

  List<BoxShadow> _buildFabShadows(
    BuildContext context, {
    required bool expanded,
  }) {
    final theme = widget.theme;
    final shadows = <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.14),
        blurRadius: 3,
        offset: const Offset(0, 3),
      ),
    ];

    if (!expanded) {
      final glowColor = theme.resolveFabGlowColor(context);
      if (glowColor != null) {
        shadows.add(
          BoxShadow(
            color: glowColor,
            blurRadius: theme.fabGlowBlur,
            spreadRadius: theme.fabGlowSpread,
            offset: Offset.zero,
          ),
        );
      }
    }

    return shadows;
  }

  Widget _buildToggleFace(BuildContext context, {required bool isExpanded}) {
    final builder = widget.fabBuilder;
    if (builder != null) {
      return builder(
        context,
        selectedItem: widget.selectedItem,
        isExpanded: isExpanded,
        onPressed: widget.controller.toggle,
        theme: widget.theme,
        actions: widget.actions,
      );
    }

    if (isExpanded) {
      return Icon(
        Icons.close,
        color: widget.theme.resolveFabForegroundColor(context),
        size: widget.theme.iconSize,
      );
    }

    return BottomNavCenterFace<T>(
      selectedItem: widget.selectedItem,
      actions: widget.actions,
      theme: widget.theme,
    );
  }
}
