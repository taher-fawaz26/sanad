import 'package:flutter/material.dart';

/// Declarative [SliverGrid] wrapper built on [SliverChildBuilderDelegate] and
/// [SliverGridDelegateWithFixedCrossAxisCount].
class AppSliverGrid extends StatelessWidget {
  const AppSliverGrid.builder({
    required this.itemBuilder,
    required this.itemCount,
    super.key,
    this.crossAxisCount = 2,
    this.spacing = 0,
    this.runSpacing = 0,
    this.childAspectRatio = 1,
  });

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final int crossAxisCount;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        itemBuilder,
        childCount: itemCount,
      ),
    );
  }
}
