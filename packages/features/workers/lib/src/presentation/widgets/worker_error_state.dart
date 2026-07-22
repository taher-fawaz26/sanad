import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:localization/localization.dart';

/// Shared `Failure` → [AppErrorState] adapter for the workers feature.
///
/// Resolves the failure to display strings via [failureErrorDisplay], picks the
/// network vs. generic treatment, and only exposes retry for retryable
/// failures. Replaces the per-page private `_ErrorState` widgets that were
/// byte-for-byte duplicated across the workers pages.
class WorkerErrorState extends StatelessWidget {
  const WorkerErrorState({required this.onRetry, this.failure, super.key});

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
