import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/src/states/app_empty_view.dart';
import 'package:shared_ui/src/states/app_error_view.dart';
import 'package:shared_ui/src/states/app_loading_view.dart';

/// Full-area loading state for direct use inside a [CustomScrollView]'s
/// `slivers` list. Fills remaining viewport height via [AppSliverFillRemaining]
/// so it never triggers intrinsic-height layout errors.
class AppSliverLoading extends StatelessWidget {
  const AppSliverLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AppSliverFillRemaining(child: AppLoadingView(message: message));
  }
}

/// Full-area empty state for direct use inside a [CustomScrollView]'s
/// `slivers` list.
class AppSliverEmpty extends StatelessWidget {
  const AppSliverEmpty({
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
    return AppSliverFillRemaining(
      child: AppEmptyView(
        title: title,
        description: description,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }
}

/// Full-area error state for direct use inside a [CustomScrollView]'s
/// `slivers` list.
class AppSliverError extends StatelessWidget {
  const AppSliverError({
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
    return AppSliverFillRemaining(
      child: AppErrorView(
        title: title,
        description: description,
        retryLabel: retryLabel,
        onRetry: onRetry,
      ),
    );
  }
}
