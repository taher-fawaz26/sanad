import 'package:flutter/widgets.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_composer_tokens.dart';

/// The live-voice control's four-bar mark — Figma `7823:28429`.
///
/// Built from rounded rectangles rather than loaded from `app_assets`
/// because Figma itself draws it that way: the node is four sibling frames
/// with their own sizes and radii, not a vector export, so there is no icon
/// asset to reference. Its bar geometry below is transcribed from those
/// nodes rather than eyeballed.
///
/// This replaces a stand-in `Icons.graphic_eq_rounded`, which had the wrong
/// silhouette entirely — five symmetric bars at Material's own proportions,
/// against Figma's four asymmetric ones.
class AiLiveVoiceGlyph extends StatelessWidget {
  /// Creates the glyph.
  const AiLiveVoiceGlyph({super.key});

  /// `(width, height)` per bar, in order — Figma nodes `7823:28430`‥`28433`.
  static const _bars = <(double, double)>[
    (2.5, 6),
    (2.5, 14),
    (2, 8),
    (3, 6),
  ];

  static const _gap = 2.0;
  static const _barRadius = Radius.circular(20);

  @override
  Widget build(BuildContext context) {
    final color = AiComposerTokens.glyph(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: _gap,
      children: [
        for (final (width, height) in _bars)
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(_barRadius),
            ),
          ),
      ],
    );
  }
}
