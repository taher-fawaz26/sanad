import 'package:flutter/material.dart';
import 'package:shared_ui/src/slivers/app_sliver_empty_builder.dart';
import 'package:shared_ui/src/slivers/app_sliver_grid.dart';

/// Builds the sliver set for a grid section that has loading/empty/error
/// states: a single loading/empty/error sliver, or an [AppSliverGrid] once
/// [items] is non-empty. See [appListBuilder] for the list equivalent.
List<Widget> appGridBuilder<T>({
  required List<T> items,
  required Widget Function(BuildContext context, T item, int index) itemBuilder,
  bool isLoading = false,
  Object? error,
  String loadingMessage = '',
  String emptyTitle = '',
  String emptyDescription = '',
  String errorTitle = '',
  String errorDescription = '',
  String errorRetryLabel = '',
  VoidCallback? onRetry,
  int crossAxisCount = 2,
  double spacing = 0,
  double runSpacing = 0,
  double childAspectRatio = 1,
}) {
  final stateSliver = buildStateSliver(
    isLoading: isLoading,
    isEmpty: items.isEmpty,
    error: error,
    loadingMessage: loadingMessage,
    emptyTitle: emptyTitle,
    emptyDescription: emptyDescription,
    errorTitle: errorTitle,
    errorDescription: errorDescription,
    errorRetryLabel: errorRetryLabel,
    onRetry: onRetry,
  );
  if (stateSliver != null) {
    return [stateSliver];
  }

  return [
    AppSliverGrid.builder(
      itemCount: items.length,
      itemBuilder: (context, index) =>
          itemBuilder(context, items[index], index),
      crossAxisCount: crossAxisCount,
      spacing: spacing,
      runSpacing: runSpacing,
      childAspectRatio: childAspectRatio,
    ),
  ];
}
