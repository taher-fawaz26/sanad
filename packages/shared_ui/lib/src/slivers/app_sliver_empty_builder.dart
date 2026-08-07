import 'package:flutter/material.dart';
import 'package:shared_ui/src/slivers/app_sliver_state.dart';

/// Shared loading/empty/error → sliver resolution used by
/// [appListBuilder]/[appGridBuilder]. Returns `null` when none of the states
/// apply, meaning the caller should render its normal content sliver.
Widget? buildStateSliver({
  required bool isLoading,
  required bool isEmpty,
  required Object? error,
  required String loadingMessage,
  required String emptyTitle,
  required String emptyDescription,
  required String errorTitle,
  required String errorDescription,
  required String errorRetryLabel,
  required VoidCallback? onRetry,
}) {
  if (isLoading) {
    return AppSliverLoading(message: loadingMessage);
  }
  if (error != null) {
    return AppSliverError(
      title: errorTitle,
      description: errorDescription,
      retryLabel: errorRetryLabel,
      onRetry: onRetry,
    );
  }
  if (isEmpty) {
    return AppSliverEmpty(title: emptyTitle, description: emptyDescription);
  }
  return null;
}
