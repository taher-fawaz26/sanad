import 'package:flutter/material.dart';

/// Thin, declaratively-named wrapper around [SliverToBoxAdapter].
///
/// Use to drop a single non-sliver widget into a [CustomScrollView] alongside
/// other `AppSliver*` widgets.
class AppSliverBox extends StatelessWidget {
  const AppSliverBox({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: child);
  }
}
