import 'package:flutter/material.dart';
import 'package:shared_ui/src/states/app_empty_state.dart';

/// Thin, purpose-named wrapper around [AppGenericEmptyState] for use as a
/// full-page or full-sliver empty state.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
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
