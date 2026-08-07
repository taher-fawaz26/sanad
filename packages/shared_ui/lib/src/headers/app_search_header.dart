import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Pinned [AppSearchField] header for use as a [CustomScrollView] sliver,
/// generalizing the pinned search-bar pattern used on list pages.
class AppSearchHeader extends StatelessWidget {
  const AppSearchHeader({
    super.key,
    this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.variant = AppSearchFieldVariant.bordered,
    this.backgroundColor,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final AppSearchFieldVariant variant;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SearchHeaderDelegate(
        height:
            responsiveDimension(FieldTokens.fieldHeight) +
            responsiveSpacing(20),
        backgroundColor: backgroundColor ?? context.appColors.surface,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: responsiveSpacing(10),
          ),
          child: AppSearchField(
            controller: controller,
            hint: hint,
            onChanged: onChanged,
            onTap: onTap,
            readOnly: readOnly,
            variant: variant,
          ),
        ),
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SearchHeaderDelegate({
    required this.height,
    required this.backgroundColor,
    required this.child,
  });

  final double height;
  final Color backgroundColor;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(color: backgroundColor, child: child);
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.child != child;
  }
}
