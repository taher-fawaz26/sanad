import 'package:flutter/material.dart';
import 'package:shared_ui/src/slivers/app_sliver_empty_builder.dart';
import 'package:shared_ui/src/slivers/app_sliver_list.dart';

/// Builds the sliver set for a list section that has loading/empty/error
/// states: a single loading/empty/error sliver, or an [AppSliverList] once
/// [items] is non-empty.
///
/// Declarative alternative to hand-writing the `if (isLoading) ... else if
/// (isEmpty) ... else AppSliverList.builder(...)` branch at every call site.
List<Widget> appListBuilder<T>({
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
  Widget Function(BuildContext context, int index)? separatorBuilder,
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
    AppSliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, index) =>
          itemBuilder(context, items[index], index),
      separatorBuilder: separatorBuilder,
    ),
  ];
}
