import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';

/// Shared `Failure` → [AppErrorState] adapter for the activity-log section —
/// resolves the failure to display strings via [failureErrorDisplay] (the
/// backend's own message when present, translated fallback otherwise) and
/// only exposes retry for retryable failures.
class ActivityLogErrorState extends StatelessWidget {
  const ActivityLogErrorState({required this.onRetry, this.failure, super.key});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final display = failureErrorDisplay(failure);
    return AppErrorState(
      style: display.isConnectivity
          ? AppErrorStateStyle.network
          : AppErrorStateStyle.generic,
      title: display.title,
      description: display.description,
      retryLabel: failureRetryLabel(),
      onRetry: display.isRetryable ? onRetry : null,
    );
  }
}
