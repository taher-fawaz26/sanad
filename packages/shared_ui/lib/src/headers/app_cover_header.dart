import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Generic collapsing cover-image header built on [SliverAppBar].
///
/// Renders a full-bleed [AppNetworkImage] behind [foreground] (e.g. a title
/// or gradient scrim), collapsing into a pinned [collapsedHeight] bar as the
/// user scrolls.
class AppCoverHeader extends StatelessWidget {
  const AppCoverHeader({
    required this.coverImageUrl,
    super.key,
    this.foreground,
    this.expandedHeight = 220,
    this.collapsedHeight = 56,
    this.pinned = true,
    this.leading,
    this.actions,
  });

  final String coverImageUrl;
  final Widget? foreground;
  final double expandedHeight;
  final double collapsedHeight;
  final bool pinned;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: pinned,
      automaticallyImplyLeading: false,
      leading: leading,
      actions: actions,
      backgroundColor: context.appColors.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(coverImageUrl),
            if (foreground != null) foreground!,
          ],
        ),
      ),
    );
  }
}
