import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:sanad_client/src/ui/glass/client_glass_tokens.dart';

/// A translucent surface that blurs whatever is behind it.
///
/// The client's AI screens sit on a standing gradient wash and, on the landing
/// state, a drifting ambient glow. Painting solid white panels over that hides
/// the thing that gives the surface its identity. Glass keeps the page visible
/// through its own chrome, which is the whole reason the background exists.
///
/// ## Why it is a component and not a `BackdropFilter` at each call site
///
/// A `BackdropFilter` is the most expensive widget in this app's vocabulary,
/// and the two ways to misuse it are invisible until a device stutters:
/// nesting them, and letting one blur more of the screen than it draws. This
/// widget makes both impossible rather than documenting them.
///
/// - **One filter per surface.** Every instance publishes a [_GlassScope], and
///   the build asserts no ancestor scope. A glass panel inside a glass panel
///   fails loudly in debug instead of silently costing two full-screen passes.
/// - **Bounded blur.** The filter is inside a `ClipRRect`, so it samples only
///   the surface's own bounds. There is no full-screen blur layer anywhere in
///   the client, and this is what keeps it that way.
/// - **Isolated repaint.** A `RepaintBoundary` outside the clip stops the
///   blurred chrome from repainting every time the content scrolling behind it
///   moves.
///
/// It sits *on top of* the existing backgrounds — `ClientAmbientBackground`,
/// `AppAmbientGradient`, the live-voice backdrop — and deliberately replaces
/// none of them.
class ClientGlassSurface extends StatelessWidget {
  /// Creates a glass surface around [child].
  const ClientGlassSurface({
    required this.child,
    required this.borderRadius,
    super.key,
    this.level = ClientGlassLevel.surface,
    this.border,
    this.shadow,
    this.padding,
    this.tint,
  });

  /// Painted over the blur.
  final Widget child;

  /// The surface's corner shape. Required, and shared by the clip, the border
  /// and the shadow: three radii that could disagree is three chances for a
  /// visible seam where the blur stops.
  final BorderRadius borderRadius;

  /// How deep the surface sits. See [ClientGlassLevel].
  final ClientGlassLevel level;

  /// Overrides the token hairline — for a surface that carries a state colour,
  /// like the composer's focused border.
  final BorderSide? border;

  /// Overrides the token shadow.
  final List<BoxShadow>? shadow;

  /// Inside the glass, so the padding is blurred along with the rest.
  final EdgeInsetsGeometry? padding;

  /// Overrides the token wash for [level].
  ///
  /// For a surface whose translucency is itself animated — the contextual
  /// sheet interpolates from a pane you can see the conversation through to an
  /// opaque one as it rises. A caller still does not choose a blur radius:
  /// only the wash moves, so the surface stays recognisably the same material
  /// at every point of the travel.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    assert(
      _GlassScope.of(context) == null,
      'ClientGlassSurface is already an ancestor of this one. Nested backdrop '
      'filters cost two full passes and the inner one has nothing new to blur '
      '— the outer surface already flattened what is behind it. Use a plain '
      'DecoratedBox for the inner panel.',
    );

    final tint = this.tint ?? ClientGlassTokens.tintFor(context, level);

    return _GlassScope(
      child: RepaintBoundary(
        child: DecoratedBox(
          // Outside the clip: a shadow drawn inside its own clip is a shadow
          // nobody can see.
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: shadow ?? ClientGlassTokens.shadowFor(context, level),
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: ClientGlassTokens.sigmaFor(level),
                sigmaY: ClientGlassTokens.sigmaFor(level),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.fromBorderSide(
                    border ??
                        BorderSide(color: ClientGlassTokens.borderFor(context)),
                  ),
                  // The tint sits under a top-edge highlight, the way light
                  // catches the lip of a real pane. A flat fill reads as
                  // tracing paper.
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.alphaBlend(
                        ClientGlassTokens.highlightFor(context),
                        tint,
                      ),
                      tint,
                    ],
                    stops: const [0, 0.45],
                  ),
                ),
                child: padding == null
                    ? child
                    : Padding(padding: padding!, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Marks that a glass surface is already in the tree above.
class _GlassScope extends InheritedWidget {
  const _GlassScope({required super.child});

  static _GlassScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GlassScope>();

  @override
  bool updateShouldNotify(_GlassScope oldWidget) => false;
}
