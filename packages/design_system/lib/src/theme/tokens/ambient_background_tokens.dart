import 'dart:math' as math;

import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/widgets.dart';

/// The app's standing page wash — Figma
/// `linear-gradient(203.89deg, #F9F9FA 59.275%, #C9FBD8 97.118%)`.
///
/// One spec, read by every surface that paints it (`Requests`, `AI Chat`,
/// `History`, the AI showcase). It lives here rather than in a feature so a
/// correction reaches all of them at once — a wash defined next to one screen
/// is a wash the next screen quietly gets wrong.
///
/// ## Why the alignments are computed rather than written down
///
/// CSS and Flutter disagree about what a gradient's endpoints mean. CSS gives
/// an **angle**, and derives the gradient line's length from the box so that
/// the first and last stops land exactly on the box's corners
/// (`L = W·|sinθ| + H·|cosθ|`). Flutter's [LinearGradient] takes two
/// [Alignment]s in normalized box space, and interpolates along whatever line
/// they describe.
///
/// Writing `topRight → bottomLeft` is only the same thing when the box has the
/// design's own aspect ratio: on Figma's 390×844 frame that diagonal happens
/// to sit within a degree of 203.89°, so it looked right and was wrong for
/// every other size. [gradient] instead solves for the alignments that
/// reproduce the CSS angle *and* the CSS gradient-line length at the box it is
/// actually painting, which makes the stop percentages below mean what Figma
/// means by them at any size.
abstract final class AmbientBackgroundTokens {
  AmbientBackgroundTokens._();

  /// Figma's CSS gradient angle, in degrees.
  ///
  /// CSS convention: 0° points at the top of the box and the angle increases
  /// clockwise, so 203.89° runs downward and slightly toward the leading edge.
  static const double angleDegrees = 203.89145362787846;

  /// Where the near-white finally starts to move — Figma's first stop.
  static const double clearStop = 0.59275;

  /// Where the mint reaches full strength — Figma's second stop. The last
  /// ~2.9% of the axis is flat mint, which is what gives the bottom edge its
  /// solid band rather than a fade that never arrives.
  static const double washStop = 0.97118;

  /// Figma's `#C9FBD8`.
  ///
  /// Deliberately a literal: it is a mint no ramp in [AppColors.palettes]
  /// carries — `main/100` (`#C3FEED`) is visibly more cyan — and this colour
  /// is what gives the client surface its identity, so matching the design
  /// beats reaching for the nearest token. It is written **once**, here.
  static const Color wash = Color(0xFFC9FBD8);

  /// The page's own near-white (`#F9F9FA`), which the theme already carries.
  static Color clear(AppColors colors) => colors.background;

  /// The wash for a box of [size], mirrored for [direction].
  ///
  /// [size] may be empty or unbounded — a background is often laid out before
  /// anything has constrained it — in which case this falls back to the
  /// leading diagonal, which is the design's own framing.
  static LinearGradient gradient({
    required AppColors colors,
    required Size size,
    required TextDirection direction,
  }) {
    const radians = angleDegrees * math.pi / 180;
    final sin = math.sin(radians);
    final cos = math.cos(radians);

    final usable =
        size.width.isFinite &&
        size.height.isFinite &&
        size.width > 0 &&
        size.height > 0;

    // The CSS gradient line: long enough that the end stops land on the
    // corners the angle points at.
    final length = usable
        ? size.width * sin.abs() + size.height * cos.abs()
        : 0.0;

    // Normalized half-extents of that line, in Alignment units (-1..1 across
    // the box). `+x` is the trailing edge in LTR, so it is negated under RTL
    // to mirror the wash with the rest of the page.
    final mirror = direction == TextDirection.rtl ? -1.0 : 1.0;
    final dx = usable ? mirror * length * sin / size.width : -mirror;
    final dy = usable ? length * cos / size.height : -1.0;

    return LinearGradient(
      begin: Alignment(-dx, dy),
      end: Alignment(dx, -dy),
      colors: [clear(colors), wash],
      stops: const [clearStop, washStop],
    );
  }
}
