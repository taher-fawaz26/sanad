import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Wrapper around [NestedScrollView] for screens that need a collapsing
/// header shared across multiple tabs (e.g. a profile page with a tab bar).
class AppNestedScrollPage extends StatelessWidget {
  const AppNestedScrollPage({
    required this.headerSliverBuilder,
    required this.body,
    super.key,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.safeArea = true,
    this.scrollController,
  });

  /// Builds the pinned/scrolling header slivers, mirroring
  /// [NestedScrollView.headerSliverBuilder].
  final List<Widget> Function(BuildContext context, bool innerBoxIsScrolled)
  headerSliverBuilder;

  /// The scrollable tab content — typically a [TabBarView].
  final Widget body;

  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool safeArea;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    Widget content = NestedScrollView(
      controller: scrollController,
      headerSliverBuilder: headerSliverBuilder,
      body: body,
    );

    if (safeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? context.appColors.surface,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: content,
    );
  }
}
