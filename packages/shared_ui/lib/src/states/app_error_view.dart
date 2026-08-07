import 'package:flutter/material.dart';
import 'package:shared_ui/src/states/app_error_state.dart';

/// Thin, purpose-named wrapper around [AppErrorState] for use as a full-page
/// or full-sliver error state.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.title,
    required this.description,
    required this.retryLabel,
    super.key,
    this.onRetry,
  });

  final String title;
  final String description;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: title,
      description: description,
      retryLabel: retryLabel,
      onRetry: onRetry,
    );
  }
}
