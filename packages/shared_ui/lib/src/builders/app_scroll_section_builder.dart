import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Builds a single [SliverMainAxisGroup] combining an [AppSection] header
/// with an arbitrary [contentSliver] — the generic building block behind
/// [AppListSection]/[AppGridSection] for sections whose content isn't a
/// plain list or grid (e.g. a custom sliver layout).
Widget appScrollSectionBuilder({
  required String title,
  required Widget contentSliver,
  String? caption,
  AppSectionTrailing trailing = AppSectionTrailing.none,
  String? trailingButtonLabel,
  VoidCallback? onTrailingTap,
}) {
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
      contentSliver,
    ],
  );
}
