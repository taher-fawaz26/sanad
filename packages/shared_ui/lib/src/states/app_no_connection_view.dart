import 'package:flutter/material.dart';
import 'package:shared_ui/src/states/app_empty_state.dart';

/// Thin, purpose-named wrapper around [AppNetworkFailureState] for use as a
/// full-page or full-sliver no-connection state.
class AppNoConnectionView extends StatelessWidget {
  const AppNoConnectionView({
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
    return AppNetworkFailureState(
      title: title,
      description: description,
      retryLabel: retryLabel,
      onRetry: onRetry,
    );
  }
}
