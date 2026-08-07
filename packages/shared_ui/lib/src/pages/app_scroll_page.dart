import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The standard scrollable page shell used across the application:
/// `Scaffold` → optional pull-to-refresh → `CustomScrollView` → `slivers`.
///
/// Generalizes the collapsing-header + refresh + list pattern used across
/// feature pages (see `branches_page.dart`) so new screens compose
/// `AppSliverAppBar`/`AppSliverSection`/`AppSliverList`/`AppSliverGrid` and
/// the `AppSliverLoading`/`AppSliverEmpty`/`AppSliverError` state slivers
/// instead of hand-rolling a `Scaffold` + `CustomScrollView`.
class AppScrollPage extends StatelessWidget {
  const AppScrollPage({
    required this.slivers,
    super.key,
    this.onRefresh,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.safeArea = true,
    this.scrollController,
    this.physics = const AlwaysScrollableScrollPhysics(),
  });

  /// Slivers rendered inside the page's [CustomScrollView].
  final List<Widget> slivers;

  /// When provided, wraps the scroll view in an [AppRefreshIndicator].
  final RefreshCallback? onRefresh;

  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool safeArea;
  final ScrollController? scrollController;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    Widget body = CustomScrollView(
      controller: scrollController,
      physics: physics,
      slivers: slivers,
    );

    final refresh = onRefresh;
    if (refresh != null) {
      body = AppRefreshIndicator(onRefresh: refresh, child: body);
    }

    if (safeArea) {
      body = SafeArea(child: body);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? context.appColors.surface,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: body,
    );
  }
}
