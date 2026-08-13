import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_ui/src/loading/app_skeletonizer.dart';

/// Skeleton placeholder for an **empty** first-page load, where there is no
/// real content yet to skeletonize.
///
/// Renders [itemCount] copies of [itemBuilder] (a representative row/card)
/// wrapped in an enabled [AppSkeletonizer], so the placeholder inherits the
/// exact layout of the real item without a bespoke skeleton widget. Once the
/// list has data, wrap the real list in [AppSkeletonizer] instead of using
/// this.
///
/// Used as the default first-page indicator for `SanadPagedList`.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({
    required this.itemBuilder,
    super.key,
    this.itemCount = 6,
    this.padding,
    this.spacing,
  });

  /// Builds one representative item. Called with each index so it can vary
  /// widths if desired; most callers ignore the index.
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Number of placeholder rows to render.
  final int itemCount;

  /// Outer padding around the placeholder column.
  final EdgeInsetsGeometry? padding;

  /// Vertical gap between placeholder rows (defaults to `AppSpacing.sm`).
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      enabled: true,
      child: ListView.separated(
        primary: false,
        padding: padding ?? EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: spacing ?? AppSpacing.sm),
        itemBuilder: itemBuilder,
      ),
    );
  }
}
