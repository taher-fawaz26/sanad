import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// [AppDivider] wrapped for direct use inside a [CustomScrollView]'s
/// `slivers` list.
class AppSliverDivider extends StatelessWidget {
  const AppSliverDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(child: AppDivider());
  }
}
