import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/src/slivers/app_sliver_grid.dart';

/// [AppSection] header followed by an [AppSliverGrid] — the sliver
/// equivalent of a titled grid section.
class AppGridSection extends StatelessWidget {
  const AppGridSection({
    required this.title,
    required this.itemBuilder,
    required this.itemCount,
    super.key,
    this.caption,
    this.trailing = AppSectionTrailing.none,
    this.trailingButtonLabel,
    this.onTrailingTap,
    this.crossAxisCount = 2,
    this.spacing = 0,
    this.runSpacing = 0,
    this.childAspectRatio = 1,
  });

  final String title;
  final String? caption;
  final AppSectionTrailing trailing;
  final String? trailingButtonLabel;
  final VoidCallback? onTrailingTap;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final int crossAxisCount;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: AppSection(
            title: title,
            caption: caption,
            size: AppSectionSize.compact,
            trailing: trailing,
            trailingButtonLabel: trailingButtonLabel,
            onTrailingTap: onTrailingTap,
          ),
        ),
        AppSliverGrid.builder(
          itemBuilder: itemBuilder,
          itemCount: itemCount,
          crossAxisCount: crossAxisCount,
          spacing: spacing,
          runSpacing: runSpacing,
          childAspectRatio: childAspectRatio,
        ),
      ],
    );
  }
}
