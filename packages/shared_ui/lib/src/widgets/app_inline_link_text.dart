import 'package:design_system/design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// One line of text where only the trailing [linkText] portion is tappable
/// and styled as a link — e.g. "Didn't find your service? Request New
/// service", where only "Request New service" is interactive.
///
/// Rendered as a single `Text.rich`/`TextSpan` so the two parts wrap and
/// align as one paragraph rather than as separate widgets.
class AppInlineLinkText extends StatelessWidget {
  const AppInlineLinkText({
    required this.text,
    required this.linkText,
    required this.onLinkTap,
    super.key,
    this.textAlign,
  });

  /// The leading, non-interactive text.
  final String text;

  /// The trailing, tappable, link-colored text.
  final String linkText;

  final VoidCallback onLinkTap;

  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final baseStyle = typography.smallNormal.copyWith(color: colors.textMuted);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text),
          TextSpan(
            text: linkText,
            style: baseStyle.copyWith(
              color: colors.link,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()..onTap = onLinkTap,
          ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
