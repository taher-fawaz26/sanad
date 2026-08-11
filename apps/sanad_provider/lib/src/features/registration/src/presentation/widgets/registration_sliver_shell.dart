import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const _kGradientStart = Color(0xFF10412F);
const _kExpandedHeight = 220.0;
const _kCardTopRadius = 48.0;
const _kHorizontalPadding = 20.0;
const _kVerticalPadding = 40.0;
const _kBackIconSize = 24.0;

/// Normalized collapse progress (`1.0` expanded → `0.0` collapsed).
///
/// Derived from [ScrollController.offset] — never stored as mutable shell
/// state.
double registrationCollapseProgress({
  required ScrollController scrollController,
  required double collapseRange,
}) {
  if (!scrollController.hasClients || collapseRange <= 0) {
    return 1;
  }
  return (1 - scrollController.offset / collapseRange).clamp(0.0, 1.0);
}

/// Sliver-based registration shell with a collapsing hero, white content sheet,
/// and measured footer overlay.
///
/// Owns scroll behavior, safe areas, collapse animation, and the white rounded
/// sheet. Pages supply hero content via [headerBuilder] and business widgets
/// via [child].
///
/// Collapse progress is a **derived layout value** computed from
/// [ScrollController.offset] on each scroll-driven rebuild. The shell does not
/// own any mutable collapse-progress state.
///
/// Steps that need a pinned footer (identity verification, trade licence, …)
/// should self-wrap in [RegistrationSliverShell] and stay excluded from the
/// module-level AuthScreenShell wrapper in RegistrationModule.
///
/// ```dart
/// RegistrationSliverShell(
///   onBack: () => RegistrationNavigation.popStep(context, ...),
///   headerBuilder: (context, t) => RegistrationLogo(collapseProgress: t),
///   footer: AppButton(...),
///   child: Column(
///     crossAxisAlignment: CrossAxisAlignment.stretch,
///     children: [/* step content only */],
///   ),
/// )
/// ```
class RegistrationSliverShell extends StatefulWidget {
  const RegistrationSliverShell({
    required this.headerBuilder,
    required this.child,
    super.key,
    this.footer,
    this.onBack,
  });

  /// Builds the collapsing hero. Receives normalized collapse progress `t`
  /// (`1.0` expanded → `0.0` collapsed) synchronized with the white sheet.
  final Widget Function(BuildContext context, double collapseProgress)
  headerBuilder;

  /// Business content rendered inside the white sheet (not scrollable itself).
  final Widget child;

  /// Pinned footer overlay. Height is measured at runtime for content inset.
  final Widget? footer;

  /// When set, shows a white back chevron in the collapsed toolbar.
  final VoidCallback? onBack;

  @override
  State<RegistrationSliverShell> createState() =>
      _RegistrationSliverShellState();
}

class _RegistrationSliverShellState extends State<RegistrationSliverShell> {
  late final ScrollController _scrollController;
  double _footerHeight = 0;

  static const _heroGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_kGradientStart, Colors.black],
    ),
  );

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onFooterSizeChanged(Size size) {
    if (_footerHeight != size.height) {
      setState(() => _footerHeight = size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final topPadding = MediaQuery.paddingOf(context).top;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final hPad = responsiveDimension(_kHorizontalPadding);
    final vPad = responsiveDimension(_kVerticalPadding);
    final maxCardRadius = responsiveDimension(_kCardTopRadius);
    final expandedHeight = responsiveDimension(_kExpandedHeight);
    final collapsedHeight = kToolbarHeight + topPadding;
    final collapseRange = expandedHeight - collapsedHeight;
    final hasFooter = widget.footer != null;
    final minSheetHeight = (viewportHeight - collapsedHeight).clamp(
      0.0,
      double.infinity,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: _heroGradient,
        child: AnimatedBuilder(
          animation: _scrollController,
          builder: (context, _) {
            final t = registrationCollapseProgress(
              scrollController: _scrollController,
              collapseRange: collapseRange,
            );
            final radius = ui.lerpDouble(0, maxCardRadius, t)!;

            return Stack(
              fit: StackFit.expand,
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: expandedHeight,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      leading: widget.onBack != null
                          ? IconButton(
                              icon: Icon(
                                Icons.chevron_left,
                                size: responsiveDimension(_kBackIconSize),
                                color: colors.white,
                              ),
                              onPressed: widget.onBack,
                            )
                          : null,
                      flexibleSpace: DecoratedBox(
                        decoration: _heroGradient,
                        child: widget.headerBuilder(context, t),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minSheetHeight),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(radius),
                              topRight: Radius.circular(radius),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            bottom: false,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                hPad,
                                vPad,
                                hPad,
                                vPad +
                                    (hasFooter ? _footerHeight : 0) +
                                    responsiveDimension(AppSpacing.lg),
                              ),
                              child: widget.child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasFooter)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _MeasureSize(
                      onChange: _onFooterSizeChanged,
                      child: _RegistrationFooterBar(
                        horizontalPadding: hPad,
                        color: colors.white,
                        child: widget.footer!,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// White action bar pinned above the safe area at the bottom of the screen.
class _RegistrationFooterBar extends StatelessWidget {
  const _RegistrationFooterBar({
    required this.horizontalPadding,
    required this.color,
    required this.child,
  });

  final double horizontalPadding;
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
            horizontalPadding,
            responsiveDimension(AppSpacing.lg),
            horizontalPadding,
            responsiveDimension(AppSpacing.lg),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Reports [RenderBox.size] changes without estimating layout.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = size;
    if (_oldSize == newSize) return;
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}
