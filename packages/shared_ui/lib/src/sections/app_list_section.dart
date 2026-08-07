import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/src/slivers/app_sliver_list.dart';

/// [AppSection] header followed by an [AppSliverList] — the sliver
/// equivalent of a titled list section.
///
/// A single sliver (built on [SliverMainAxisGroup]) — drop it directly into a
/// [CustomScrollView]'s `slivers` list.
class AppListSection extends StatelessWidget {
  const AppListSection({
    required this.title,
    required this.itemBuilder,
    required this.itemCount,
    super.key,
    this.caption,
    this.trailing = AppSectionTrailing.none,
    this.trailingIcon,
    this.trailingButtonLabel,
    this.onTrailingTap,
    this.separatorBuilder,
  });

  final String title;
  final String? caption;
  final AppSectionTrailing trailing;

  /// Icon when [trailing] is [AppSectionTrailing.icon].
  final Widget? trailingIcon;
  final String? trailingButtonLabel;
  final VoidCallback? onTrailingTap;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final IndexedWidgetBuilder? separatorBuilder;

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
            trailingIcon: trailingIcon,
            trailingButtonLabel: trailingButtonLabel,
            onTrailingTap: onTrailingTap,
          ),
        ),
        AppSliverList.builder(
          itemBuilder: itemBuilder,
          itemCount: itemCount,
          separatorBuilder: separatorBuilder,
        ),
      ],
    );
  }
}
