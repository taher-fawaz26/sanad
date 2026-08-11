import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Generic collapsing full-bleed image header built on [SliverAppBar].
///
/// Unlike [AppCoverHeader], this variant has no baked-in foreground scrim —
/// pass [overlay] for a gradient, title, or any custom content on top of the
/// image.
class AppImageHeader extends StatelessWidget {
  const AppImageHeader({
    this.imageUrl,
    super.key,
    this.overlay,
    this.expandedHeight = 280,
    this.pinned = true,
    this.stretch = false,
    this.leading,
    this.actions,
  });

  final String? imageUrl;
  final Widget? overlay;
  final double expandedHeight;
  final bool pinned;
  final bool stretch;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: pinned,
      stretch: stretch,
      automaticallyImplyLeading: false,
      leading: leading,
      actions: actions,
      backgroundColor: context.appColors.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      expandedHeight: expandedHeight,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(imageUrl ?? ''),
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }
}
