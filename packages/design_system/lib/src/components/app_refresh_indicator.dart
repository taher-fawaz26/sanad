import 'package:flutter/material.dart';

/// Themed pull-to-refresh wrapper built on [RefreshIndicator].
///
/// Uses Material 3 [ColorScheme] so it adapts to light / dark theme
/// automatically. API mirrors [RefreshIndicator] — drop-in replacement.
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    required this.onRefresh,
    required this.child,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
    super.key,
  });

  final RefreshCallback onRefresh;
  final Widget child;
  final ScrollNotificationPredicate notificationPredicate;
  final double displacement;
  final double edgeOffset;
  final RefreshIndicatorTriggerMode triggerMode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      notificationPredicate: notificationPredicate,
      displacement: displacement,
      edgeOffset: edgeOffset,
      triggerMode: triggerMode,
      child: child,
    );
  }
}
