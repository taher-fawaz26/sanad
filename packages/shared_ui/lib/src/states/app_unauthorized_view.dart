import 'package:flutter/material.dart';
import 'package:shared_ui/src/states/app_empty_state.dart';

/// Empty-state variant for "you don't have access" screens/sections.
class AppUnauthorizedView extends StatelessWidget {
  const AppUnauthorizedView({
    required this.title,
    required this.description,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppGenericEmptyState(
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
