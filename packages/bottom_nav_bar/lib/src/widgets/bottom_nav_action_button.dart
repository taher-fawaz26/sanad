import 'package:bottom_nav_bar/src/models/bottom_nav_action.dart';
import 'package:bottom_nav_bar/src/theme/bottom_nav_theme_data.dart';
import 'package:flutter/material.dart';

/// Internal fan child for one center action.
class BottomNavActionButton<T> extends StatelessWidget {
  const BottomNavActionButton({
    required this.action,
    required this.theme,
    required this.onPressed,
    super.key,
  });

  final BottomNavAction<T> action;
  final BottomNavThemeData theme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = action.semanticLabel ?? action.label ?? '';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: FloatingActionButton.small(
        heroTag: null,
        backgroundColor: theme.resolveFabBackgroundColor(context),
        onPressed: onPressed,
        child: action.iconBuilder(context, selected: true),
      ),
    );
  }
}
