import 'package:flutter/material.dart';

/// Fixed-size vertical spacer for use directly inside a [CustomScrollView]'s
/// `slivers` list — the sliver equivalent of a [SizedBox] gap.
class AppSliverGap extends StatelessWidget {
  const AppSliverGap(this.height, {super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: SizedBox(height: height));
  }
}
