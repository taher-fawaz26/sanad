import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_circle_icon_button.dart';

/// Conversation History's top row — Figma `Bars / Nav Bars: Standard`
/// (`8120:3289`): a back chevron at the leading edge, the title centred, and
/// the same clock glyph the Home header carries at the trailing edge.
///
/// Not [AppNavBar], and not a Material `AppBar`. Both paint their own opaque
/// surface (`AppNavBar` resolves `colors.white`), and this row sits *on* the
/// AI surface's gradient — an opaque bar across the top is exactly the band
/// `AiHomeShell` was restructured to remove. It also follows the AI header's
/// own pattern: chrome is a widget inside the body, over the wash, rather
/// than a `Scaffold.appBar` above it. Figma's title is 16dp SemiBold where
/// `AppNavBar` resolves 18dp Regular, so adopting the shared bar would have
/// meant restyling every nav bar in both apps to fix one screen.
class ConversationHistoryNavBar extends StatelessWidget {
  /// Creates the row.
  const ConversationHistoryNavBar({required this.onBack, super.key});

  /// Fired when the back chevron is tapped.
  final VoidCallback onBack;

  /// Figma's glyph slots (`size-[24px]`).
  static const double _glyphSize = 24;

  /// Figma's row: `py-[12px]` around a 24dp glyph.
  static const double _rowHeight = 48;

  /// Figma's `px-[20px]` — the inset to the *glyphs*, which is what the eye
  /// reads as the page margin.
  static const double _pageInset = 20;

  /// The back control's tap target. Figma draws a bare 24dp glyph; a 24dp
  /// touch target is half the platform minimum, so the button is 48dp and
  /// [_backInset] pulls it back by the difference — the glyph lands exactly
  /// where Figma puts it and the extra area is invisible.
  static const double _backTapTarget = 48;
  static const double _backInset =
      _pageInset - (_backTapTarget - _glyphSize) / 2;

  /// How far the title is held clear of either control: the page inset, the
  /// glyph, and a gap so a long translation ellipsizes rather than touching.
  static const double _titleInset = _pageInset + _glyphSize + 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      // A minimum, not a fixed height: the title is the only child that grows
      // with the user's text scale, and at a large scale the row has to give
      // it the room rather than clip it.
      constraints: const BoxConstraints(minHeight: _rowHeight),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Unpositioned, so this is what sizes the Stack. Centred in the
          // whole row rather than in the gap between the controls, which is
          // what keeps the title optically centred when one side is wider.
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: AppSpacing.md,
              bottom: AppSpacing.md,
              start: _titleInset,
              end: _titleInset,
            ),
            child: Text(
              'history.title'.tr(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // Figma: 16dp SemiBold `#111827` — the design system's
              // `regular` tier at `textPrimary`.
              style: context.appTypography.regularNone.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          PositionedDirectional(
            start: _backInset,
            top: 0,
            bottom: 0,
            child: Center(
              child: AiCircleIconButton(
                // The same Material chevron `AppNavBar` draws for a back
                // action, at Figma's 24dp.
                icon: Icons.chevron_left,
                semanticLabel: 'history.back'.tr(),
                size: _backTapTarget,
                iconSize: _glyphSize,
                iconColor: colors.palettes.dark.shade950,
                onTap: onBack,
              ),
            ),
          ),
          PositionedDirectional(
            end: _pageInset,
            top: 0,
            bottom: 0,
            // Present in Figma (`8120:3285`) and inert by design: it is the
            // History glyph, and this *is* History. Drawn so the row matches
            // the design, but given no tap target and no button role — a
            // control that looks enabled and navigates nowhere is worse than
            // a decorative mark.
            child: ExcludeSemantics(
              child: Center(
                child: AppSvgPicture.asset(
                  AppSvgs.aiChatNavHistory,
                  width: _glyphSize,
                  height: _glyphSize,
                  colorFilter: ColorFilter.mode(
                    colors.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
