import 'package:flutter/material.dart';

/// Thin, declaratively-named wrapper around [SliverPadding].
class AppSliverPadding extends StatelessWidget {
  const AppSliverPadding({
    required this.padding,
    required this.sliver,
    super.key,
  });

  final EdgeInsetsGeometry padding;
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(padding: padding, sliver: sliver);
  }
}
