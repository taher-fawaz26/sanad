import 'dart:ui' show lerpDouble;

import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/context/ai_chat_context_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/context/ai_chat_layout.dart';
import 'package:sanad_client/src/ui/glass/client_glass_surface.dart';

/// The chat's contextual surface — Figma `8428:37645` (at rest) and
/// `8433:38413` (open).
///
/// ## The one visual idea
///
/// It is **one surface whose material changes as it rises**. At rest it is a
/// pane of glass tucked behind the composer: you read the conversation's
/// background straight through it, and all that shows is a strip carrying the
/// agent's summary. Dragging it up turns that same pane opaque, widens it a
/// little, and swaps the summary for a drag handle. There is no moment where a
/// white rectangle appears — the fill, the inset, the border and the shadow are
/// all interpolated on the layer's own extent.
///
/// ## What it is not
///
/// Not a route, not a modal, not a bottom sheet, and not an overlay. It is one
/// slot of the chat page's own layout (see [AiChatLayout]), which is what lets
/// the composer stay above it and stay interactive at every extent. It is also
/// deliberately Chat-local: `packages/sheet_navigation` owns sheets that are
/// routes, and nothing here belongs in that vocabulary.
///
/// ## What it knows
///
/// Presentation only. It is handed a [peekLabel] and a [child] and renders
/// them; it has never heard of offers, providers or requests. The content comes
/// from `ChatContextCubit`, which is fed by the transport — so the surface
/// cannot invent business data even by accident, and a second kind of context
/// arriving later needs no change here.
class AiChatContextLayer extends StatefulWidget {
  /// Creates the contextual layer.
  const AiChatContextLayer({
    required this.peekLabel,
    required this.child,
    super.key,
    this.controller,
    this.bleed = AiChatLayout.defaultBleed,
    this.onExtentChanged,
  });

  /// The drag strip. Named so a test can drive the layer by the same region a
  /// finger does, rather than by a coordinate that moves with the chrome.
  static const Key headerKey = Key('ai_chat_context_layer_header');

  /// The summary on the affordance — "You have 8 new offers". Agent-supplied
  /// prose, rendered verbatim; the client adds its own localized call to
  /// action beside it.
  final String peekLabel;

  /// What the layer renders once opened. Already-rendered content: the layer
  /// is a container, so this is an `AiUiSurface` over the agent's document and
  /// the cards inside it are the renderer's, not this widget's.
  final Widget child;

  /// Lets the page ask the layer to open or close.
  final AiChatContextController? controller;

  /// Must match [AiChatLayout.bleed].
  final double bleed;

  /// Fired when the layer settles somewhere new.
  final ValueChanged<AiChatContextExtent>? onExtentChanged;

  @override
  State<AiChatContextLayer> createState() => _AiChatContextLayerState();
}

class _AiChatContextLayerState extends State<AiChatContextLayer>
    with SingleTickerProviderStateMixin {
  /// Height of the strip that shows above the composer at rest.
  ///
  /// Figma leaves 34 dp of surface proud of the composer's top edge; rounded up
  /// so the strip is also a comfortable drag target.
  static double get _peekExtent => responsiveDimension(40);

  /// How much of the height above the composer the open layer takes.
  ///
  /// Sized to Figma's composition — two offer cards and the handle — rather
  /// than to the screen, so the layer does not open into empty white.
  static const double _expandedFraction = 0.82;

  static double get _restInset => responsiveDimension(40);
  static double get _openInset => responsiveDimension(29);

  /// Snaps past this share of the travel, or faster than [_flingVelocity],
  /// commit to the extent the drag was heading for.
  static const double _snapThreshold = 0.35;
  static const double _flingVelocity = 700;

  /// 0 at the peek strip, 1 fully open. Driven directly by the drag, so the
  /// surface follows the finger rather than animating towards it.
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: AppMotionDuration.normal,
  );

  /// The travel available to a drag, measured at layout time.
  double _travel = 1;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerRequest);
    _progress.addStatusListener(_onSettled);
  }

  @override
  void didUpdateWidget(AiChatContextLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller?.removeListener(_onControllerRequest);
    widget.controller?.addListener(_onControllerRequest);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerRequest);
    _progress
      ..removeStatusListener(_onSettled)
      ..dispose();
    super.dispose();
  }

  void _onControllerRequest() {
    switch (widget.controller?.requested) {
      case AiChatContextExtent.expanded:
        _settle(open: true);
      case AiChatContextExtent.peek || AiChatContextExtent.collapsed:
        _settle(open: false);
      case null:
        break;
    }
  }

  void _onSettled(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onExtentChanged?.call(AiChatContextExtent.expanded);
    } else if (status == AnimationStatus.dismissed) {
      widget.onExtentChanged?.call(AiChatContextExtent.peek);
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // Upward is negative in screen coordinates and positive in progress, which
    // is the one sign flip in the whole widget.
    _progress.value = (_progress.value - details.primaryDelta! / _travel).clamp(
      0.0,
      1.0,
    );
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = -details.velocity.pixelsPerSecond.dy;
    // A deliberate flick wins over position: someone who throws the layer
    // upward from a third of the way meant to open it.
    if (velocity.abs() > _flingVelocity) {
      _settle(open: velocity > 0);
      return;
    }
    _settle(open: _progress.value > _snapThreshold);
  }

  void _settle({required bool open}) {
    // Reduced motion means no travel animation, not no movement: the layer
    // still goes where it was asked, it just arrives at once.
    if (AppMotion.reduceMotionOf(context)) {
      _progress.value = open ? 1 : 0;
      return;
    }

    if (open) {
      _progress.animateTo(1, curve: AppMotionCurve.emphasizedDecelerate);
    } else {
      _progress.animateBack(0, curve: AppMotionCurve.emphasizedDecelerate);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // The slot is `conversationHeight + bleed` tall (see `AiChatLayout`), so
      // the panel's own height runs from the peek strip up to the expanded
      // fraction of the conversation area, plus the bleed it hides behind the
      // composer.
      final conversation = constraints.maxHeight - widget.bleed;
      final closed = _peekExtent + widget.bleed;
      final open = conversation * _expandedFraction + widget.bleed;
      _travel = (open - closed).clamp(1.0, double.infinity);

      return Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedBuilder(
          animation: _progress,
          builder: (context, child) {
            final progress = _progress.value;
            return SizedBox(
              height: lerpDouble(closed, open, progress),
              width: double.infinity,
              child: _surface(
                context,
                progress,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The whole strip is the drag target, and it stays mounted
                    // at every extent: a gesture target that unmounts partway
                    // through a drag cancels the drag.
                    GestureDetector(
                      key: AiChatContextLayer.headerKey,
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: _onDragUpdate,
                      onVerticalDragEnd: _onDragEnd,
                      onTap: () => _settle(open: progress < 0.5),
                      child: _Header(
                        label: widget.peekLabel,
                        progress: progress,
                        height: _peekExtent,
                      ),
                    ),
                    // Clipped rather than removed, so the content is laid out
                    // once and the reveal is pure geometry.
                    Expanded(
                      child: ClipRect(
                        child: Opacity(
                          opacity: (progress * 2.5).clamp(0.0, 1.0),
                          child: child,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: _Body(bleed: widget.bleed, child: widget.child),
        ),
      );
    },
  );

  /// Glass at rest, an opaque sheet when open, and every frame in between.
  Widget _surface(BuildContext context, double progress, Widget child) {
    final colors = context.appColors;
    // Eased so the surface commits to being opaque early in the travel: the
    // content has to be readable before the layer stops moving.
    final t = Curves.easeOutCubic.transform(progress);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        // The layer is narrower than the composer at every extent — that is the
        // cue that says "this is behind it" — and widens slightly as it opens.
        // Figma: 40 dp inset at rest, 29 dp open, against the composer's 20 dp.
        horizontal: lerpDouble(_restInset, _openInset, t)!,
      ),
      child: ClientGlassSurface(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        // Figma: `rgba(255,255,255,0.6)` at rest, `Sky/50` opaque when open.
        tint: Color.lerp(
          colors.white.withValues(alpha: 0.6),
          colors.slate50,
          t,
        ),
        // A translucent pane needs an edge or it dissolves into the wash; an
        // opaque one needs the design system's own hairline.
        border: BorderSide(
          color: Color.lerp(
            colors.border.withValues(alpha: 0.4),
            colors.border,
            t,
          )!,
        ),
        // Upward, because the only edge of a rising layer anyone can see is its
        // top one. Deepens as it lifts clear of the page.
        shadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(
              alpha: lerpDouble(0.04, 0.12, t),
            ),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
        child: child,
      ),
    );
  }
}

/// The layer's top strip: the affordance at rest, the drag handle when open.
///
/// One slot, two readings, cross-faded on the layer's own progress — so the
/// summary hands over to the handle as part of the same movement rather than as
/// a second animation.
class _Header extends StatelessWidget {
  const _Header({
    required this.label,
    required this.progress,
    required this.height,
  });

  final String label;
  final double progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    // The affordance is gone by a fifth of the way up; the handle arrives just
    // after, so the two never read as a dissolve.
    final affordance = (1 - progress * 5).clamp(0.0, 1.0);
    final handle = ((progress - 0.15) * 4).clamp(0.0, 1.0);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (affordance > 0)
            Opacity(
              opacity: affordance,
              child: _Affordance(label: label),
            ),
          if (handle > 0) Opacity(opacity: handle, child: const _Handle()),
        ],
      ),
    );
  }
}

/// "You have 8 new offers · Swipe up" plus the swiping hand — Figma
/// `8428:37442`.
class _Affordance extends StatelessWidget {
  const _Affordance({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          Flexible(
            child: Text(
              '$label · ${'ai_chat.context_swipe_up'.tr()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.smallNormal.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
          // Vertical motion, so the glyph is direction-neutral and is
          // deliberately not mirrored in Arabic.
          AppSvgPicture.asset(
            AppSvgs.aiSwipeUpHand,
            width: responsiveDimension(32),
            height: responsiveDimension(27),
          ),
        ],
      ),
    );
  }
}

/// The grab handle, taken from the same tokens every other sheet uses.
class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    final spec = BottomSheetTokens.resolve(
      colors: context.appColors,
      typography: context.appTypography,
      brightness: Theme.of(context).brightness,
    );

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: spec.dragHandleTopPadding),
        child: Container(
          width: spec.dragHandleWidth,
          height: spec.dragHandleHeight,
          decoration: BoxDecoration(
            color: spec.dragHandleColor,
            borderRadius: BorderRadius.circular(spec.dragHandleHeight / 2),
          ),
        ),
      ),
    );
  }
}

/// The contextual content, scrolled inside the layer.
class _Body extends StatelessWidget {
  const _Body({required this.bleed, required this.child});

  final double bleed;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg),
    child: SingleChildScrollView(
      // The panel's own box runs `bleed` pixels behind the composer, so the
      // last card needs that much clearance plus a breath to be readable.
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: bleed + AppSpacing.lg,
      ),
      child: child,
    ),
  );
}
