import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Collapsing [SliverAppBar] that hosts an [AppNavBar] or [AppLargeNavBar] as
/// its collapsed title bar, with optional expanded content above it and a
/// pinned [bottom] widget (e.g. a search field).
///
/// Pass [navBar] for the standard compact bar, or [largeNavBar] for the large
/// title variant — exactly one should be provided.
class AppSliverAppBar extends StatelessWidget {
  const AppSliverAppBar({
    super.key,
    this.navBar,
    this.largeNavBar,
    this.expandedContent,
    this.expandedHeight,
    this.bottom,
    this.pinned = true,
    this.backgroundColor,
  }) : assert(
         (navBar != null) ^ (largeNavBar != null),
         'Provide exactly one of navBar or largeNavBar.',
       );

  final AppNavBar? navBar;
  final AppLargeNavBar? largeNavBar;

  /// Optional content shown above the nav bar while expanded (e.g. a hero
  /// image or a title row that collapses away on scroll).
  final Widget? expandedContent;

  /// Total expanded height. Defaults to the nav bar's [PreferredSizeWidget]
  /// height plus the height of [expandedContent], if any.
  final double? expandedHeight;

  /// Pinned widget shown below the collapsing area (e.g. a search field).
  final PreferredSizeWidget? bottom;

  final bool pinned;
  final Color? backgroundColor;

  PreferredSizeWidget get _navBar => (navBar ?? largeNavBar)!;

  @override
  Widget build(BuildContext context) {
    final navBarHeight = _navBar.preferredSize.height;
    final content = expandedContent;

    return SliverAppBar(
      pinned: pinned,
      toolbarHeight: 0,
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor ?? context.appColors.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      expandedHeight: expandedHeight ?? navBarHeight,
      flexibleSpace: FlexibleSpaceBar(
        background: content == null
            ? _navBar
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  content,
                  _navBar,
                ],
              ),
      ),
      bottom: bottom,
    );
  }
}
