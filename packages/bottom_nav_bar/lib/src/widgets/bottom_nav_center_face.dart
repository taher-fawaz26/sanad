import 'package:bottom_nav_bar/src/models/bottom_nav_action.dart';
import 'package:bottom_nav_bar/src/theme/bottom_nav_theme_data.dart';
import 'package:bottom_nav_bar/src/widgets/bottom_nav_selection.dart';
import 'package:flutter/material.dart';

/// Internal default center control face (+ or selected action icon).
class BottomNavCenterFace<T> extends StatelessWidget {
  const BottomNavCenterFace({
    required this.selectedItem,
    required this.actions,
    required this.theme,
    super.key,
  });

  final T? selectedItem;
  final List<BottomNavAction<T>> actions;
  final BottomNavThemeData theme;

  @override
  Widget build(BuildContext context) {
    final selectedAction = BottomNavSelection.findAction(selectedItem, actions);
    if (selectedAction != null) {
      return selectedAction.iconBuilder(context, selected: true);
    }

    return Icon(
      Icons.add,
      color: theme.resolveFabForegroundColor(context),
      size: theme.iconSize,
    );
  }
}
