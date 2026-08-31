import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const _kGradientStart = Color(0xFF10412F);
const _kExpandedHeight = 220.0;
const _kLogoWidth = 225.0;
const _kLogoHeight = 73.0;
const _kSmallLogoWidth = 90.0;
const _kSmallLogoHeight = 29.0;
const _kCardTopRadius = 48.0;
const _kHorizontalPadding = 20.0;
const _kVerticalPadding = 40.0;
const _kBackIconSize = 24.0;

/// Sliver-based gradient-hero scaffold shared by authentication and
/// registration screens.
///
/// The scroll owns the whole screen. The hero lives in a collapsing, pinned
/// [SliverAppBar]:
///   * Expanded — a large, centered Sanad logo over the gradient.
///   * Collapsed — the logo shrinks and crossfades into a compact top bar
///     showing a small logo alongside the page [title].
///
/// [child] is a plain box widget (typically a `Column`). It is placed inside a
/// white rounded card via [SliverFillRemaining] so that short content pins a
/// trailing `Spacer()` + button to the bottom, while tall content grows past
/// the viewport and scrolls naturally.
///
/// When [onBack] is provided, a white chevron is shown in the top bar.
class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    required this.child,
    super.key,
    this.onBack,
    this.title,
    this.footer,
    this.horizontalPadding,
  });

  final Widget child;
  final VoidCallback? onBack;

  /// Page title shown in the collapsed top bar next to the small logo.
  /// When null the collapsed bar shows only the small logo.
  final String? title;

  /// Optional action bar pinned to the bottom of the screen. It stays visible
  /// above the scrolling content (e.g. a "Continue" button on a long upload
  /// form) instead of scrolling away with [child].
  final Widget? footer;

  /// Overrides the card's default horizontal inset around [child].
  ///
  /// Only needed when [child] already applies its own horizontal padding
  /// (e.g. `OtpView`, whose `AppSpacing.xl` padding is otherwise doubled up
  /// with this shell's) — pass `0` in that case so the two don't stack.
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final topPadding = MediaQuery.of(context).padding.top;
    final hPad = horizontalPadding ?? responsiveDimension(_kHorizontalPadding);
    final vPad = responsiveDimension(_kVerticalPadding);
    final cardRadius = responsiveDimension(_kCardTopRadius);
    final expandedHeight = responsiveDimension(_kExpandedHeight);
    final hasFooter = footer != null;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kGradientStart, Colors.black],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: expandedHeight,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    leading: onBack != null
                        ? IconButton(
                            icon: Icon(
                              Icons.chevron_left,
                              size: responsiveDimension(_kBackIconSize),
                              color: colors.white,
                            ),
                            onPressed: onBack,
                          )
                        : null,
                    flexibleSpace: _HeroFlexibleSpace(
                      expandedHeight: expandedHeight,
                      topPadding: topPadding,
                      title: title,
                    ),
                  ),
                  // White rounded card. _IntrinsicBarrier returns 0 for
                  // intrinsic height so LayoutBuilder descendants never
                  // throw "does not support intrinsic dimensions".
                  // SliverFillRemaining then gives tight constraints =
                  // remaining viewport, keeping Spacer / Expanded working.
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _IntrinsicBarrier(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(cardRadius),
                            topRight: Radius.circular(cardRadius),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          bottom: !hasFooter,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              hPad,
                              vPad,
                              hPad,
                              hasFooter ? 0 : vPad,
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasFooter)
              _FooterBar(hPad: hPad, color: colors.white, child: footer!),
          ],
        ),
      ),
    );
  }
}

/// White action bar pinned below the scroll area (always visible).
class _FooterBar extends StatelessWidget {
  const _FooterBar({
    required this.hPad,
    required this.color,
    required this.child,
  });

  final double hPad;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            hPad,
            responsiveDimension(AppSpacing.lg),
            hPad,
            responsiveDimension(AppSpacing.lg),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Gradient hero that crossfades between a large centered logo (expanded) and a
/// compact logo + title bar (collapsed) as the [SliverAppBar] shrinks.
class _HeroFlexibleSpace extends StatelessWidget {
  const _HeroFlexibleSpace({
    required this.expandedHeight,
    required this.topPadding,
    required this.title,
  });

  final double expandedHeight;
  final double topPadding;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final collapsedHeight = kToolbarHeight + topPadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final range = (expandedHeight - collapsedHeight).clamp(
          1.0,
          expandedHeight,
        );
        // 1.0 fully expanded → 0.0 fully collapsed.
        final t = ((constraints.maxHeight - collapsedHeight) / range).clamp(
          0.0,
          1.0,
        );

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kGradientStart, Colors.black],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Expanded: large centered logo.
              Opacity(
                opacity: t,
                child: Padding(
                  padding: EdgeInsets.only(top: topPadding),
                  child: Center(
                    child: AppSvgPicture.asset(
                      AppSvgs.sanadLogo,
                      width: responsiveDimension(_kLogoWidth),
                      height: responsiveDimension(_kLogoHeight),
                    ),
                  ),
                ),
              ),
              // Collapsed: small logo + page title in the top bar.
              Opacity(
                opacity: 1 - t,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: collapsedHeight,
                    padding: EdgeInsets.only(top: topPadding),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSvgPicture.asset(
                          AppSvgs.sanadLogo,
                          width: responsiveDimension(_kSmallLogoWidth),
                          height: responsiveDimension(_kSmallLogoHeight),
                        ),
                        if (title != null) ...[
                          SizedBox(width: responsiveDimension(AppSpacing.md)),
                          Flexible(
                            child: Text(
                              title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: typography.regularNormal.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Transparent proxy that returns 0 for intrinsic height queries.
///
/// [SliverFillRemaining] with `hasScrollBody: false` calls
/// `getMaxIntrinsicHeight` on its child. If any descendant is a [LayoutBuilder]
/// (which cannot answer intrinsic queries), Flutter throws. Placing this widget
/// directly inside [SliverFillRemaining] intercepts that query and returns 0,
/// so [SliverFillRemaining] falls back to the remaining viewport height as the
/// tight layout extent — the correct behaviour for registration shell pages.
class _IntrinsicBarrier extends SingleChildRenderObjectWidget {
  const _IntrinsicBarrier({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderIntrinsicBarrier();
}

class _RenderIntrinsicBarrier extends RenderProxyBox {
  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;
}
