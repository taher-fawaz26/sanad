import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A compact circular icon button — the composer's plus/mic/live-voice
/// controls and the nav pill's collapsed segments.
///
/// Not [AppIconButton]: that component's smallest tap target is a fixed
/// 44dp, protecting the platform minimum-touch-target guideline everywhere
/// else in the app. Figma specifies exactly 36dp for these controls, in a
/// deliberately dense composer toolbar — the same tradeoff dense chat-app
/// toolbars make everywhere. [semanticLabel] keeps it accessible regardless
/// of the visual size.
class AiCircleIconButton extends StatelessWidget {
  /// Creates the button. Provide exactly one of [icon] or [svgAsset].
  const AiCircleIconButton({
    required this.semanticLabel,
    super.key,
    this.icon,
    this.svgAsset,
    this.child,
    this.onTap,
    this.size = 36,
    this.iconSize = 18,
    this.background,
    this.iconColor,
  }) : assert(
         (icon == null ? 0 : 1) +
                 (svgAsset == null ? 0 : 1) +
                 (child == null ? 0 : 1) ==
             1,
         'Provide exactly one of icon, svgAsset or child.',
       );

  /// A Material glyph. Mutually exclusive with [svgAsset] and [child].
  final IconData? icon;

  /// An `app_assets` SVG path. Mutually exclusive with [icon] and [child].
  final String? svgAsset;

  /// A pre-built mark, for the one control Figma composes from primitives
  /// rather than exporting as an icon (see `AiLiveVoiceGlyph`). It sizes and
  /// colors itself, so [iconSize] and [iconColor] do not apply to it.
  final Widget? child;

  /// Called on tap; `null` disables the button.
  final VoidCallback? onTap;

  /// The circle's diameter.
  final double size;

  /// The glyph's size within the circle.
  final double iconSize;

  /// Fill behind the glyph; transparent when unset.
  final Color? background;

  /// Glyph tint; defaults to [AppColors.textSecondary].
  final Color? iconColor;

  /// Accessible name — required, since an icon-only control has none of its
  /// own.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tint = iconColor ?? colors.textSecondary;

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onTap != null,
      child: Material(
        color: background ?? Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child:
                  child ??
                  (svgAsset != null
                      ? SvgPicture.asset(
                          svgAsset!,
                          package: AppAssets.package,
                          width: iconSize,
                          height: iconSize,
                          colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
                        )
                      : Icon(icon, size: iconSize, color: tint)),
            ),
          ),
        ),
      ),
    );
  }
}
