import 'package:design_system/src/shared_ui/app_empty_state.dart';
import 'package:flutter/material.dart';

/// Visual treatment for [AppErrorState].
enum AppErrorStateStyle {
  /// Connectivity-style illustration (no internet / timeout).
  network,

  /// Generic error illustration (server / unknown / business errors).
  generic,
}

/// Generic, failure-agnostic full-area error state with an optional retry
/// action. Replaces the per-feature private `_ErrorState` widgets.
///
/// This component knows nothing about `Failure` types or i18n keys — callers
/// resolve those (via the failure resolver) and pass in display strings plus a
/// [style]. See the Component Ownership Policy in `docs/ARCHITECTURE.md`.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.title,
    required this.description,
    required this.retryLabel,
    super.key,
    this.onRetry,
    this.style = AppErrorStateStyle.generic,
  });

  final String title;
  final String description;
  final String retryLabel;
  final VoidCallback? onRetry;
  final AppErrorStateStyle style;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: switch (style) {
        AppErrorStateStyle.network => AppNetworkFailureState(
            title: title,
            description: description,
            retryLabel: retryLabel,
            onRetry: onRetry,
          ),
        AppErrorStateStyle.generic => AppGenericEmptyState(
            title: title,
            description: description,
            actionLabel: retryLabel,
            onAction: onRetry,
          ),
      },
    );
  }
}
