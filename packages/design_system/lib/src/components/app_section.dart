import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/button_tokens.dart';
import 'package:design_system/src/theme/tokens/nav_bar_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

/// Figma section header size.
enum AppSectionSize {
  /// `_Partials / Tables` (`194:3008`) — compact in-content header.
  compact,

  /// `Bars / Nav Bars: Large` (`40:6931`) — large screen section header.
  large,
}

/// Section title color tone.
enum AppSectionTone {
  /// Default dark title (`73:2909`).
  normal,

  /// Teal primary title — form section headers (`194:4351`).
  primary,
}

/// Figma large section trailing slot (`40:6931`).
enum AppSectionTrailing {
  /// Title / caption only (`40:6932`, `40:6939`).
  none,

  /// Trailing 24 dp icon (`40:6955`, `40:6950`).
  icon,

  /// Trailing small primary button (`40:6947`, `40:6942`).
  button,

  /// Arbitrary trailing widget.
  custom,
}

/// Reusable section header for any screen.
///
/// Large variants (Figma `Bars / Nav Bars: Large`):
/// - Title only (`40:6932`)
/// - Title + trailing button (`40:6947`)
/// - Title + trailing icon (`40:6955`)
/// - Title + caption (`40:6939`)
/// - Title + caption + button (`40:6942`)
/// - Title + caption + icon (`40:6950`)
/// - Title ± caption + custom trailing
class AppSection extends StatelessWidget {
  const AppSection({
    required this.title,
    super.key,
    this.caption,
    this.size = AppSectionSize.large,
    this.tone = AppSectionTone.normal,
    this.trailing = AppSectionTrailing.none,
    this.trailingIcon,
    this.trailingButtonLabel,
    this.trailingWidget,
    this.onTrailingTap,
    this.padding,
  });

  final String title;
  final String? caption;
  final AppSectionSize size;
  final AppSectionTone tone;

  /// Trailing slot — none / icon / button / custom.
  final AppSectionTrailing trailing;

  /// Icon when [trailing] is [AppSectionTrailing.icon].
  final Widget? trailingIcon;

  /// Button label when [trailing] is [AppSectionTrailing.button].
  final String? trailingButtonLabel;

  /// Widget when [trailing] is [AppSectionTrailing.custom].
  final Widget? trailingWidget;

  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? _resolvePadding(context);

    return Padding(
      padding: effectivePadding,
      child: size == AppSectionSize.compact
          ? _CompactSection(
              title: title,
              caption: caption,
              tone: tone,
              trailing: trailing,
              trailingIcon: trailingIcon,
              trailingButtonLabel: trailingButtonLabel,
              trailingWidget: trailingWidget,
              onTrailingTap: onTrailingTap,
            )
          : _LargeSection(
              title: title,
              caption: caption,
              trailing: trailing,
              trailingIcon: trailingIcon,
              trailingButtonLabel: trailingButtonLabel,
              trailingWidget: trailingWidget,
              onTrailingTap: onTrailingTap,
            ),
    );
  }

  EdgeInsetsGeometry _resolvePadding(BuildContext context) {
    if (size == AppSectionSize.compact) {
      // Figma `73:2909` — px 20, py 8.
      return EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      );
    }
    final horizontal = context.appNavBarTheme.large.horizontalPadding;
    return EdgeInsets.symmetric(horizontal: horizontal);
  }
}

class _CompactSection extends StatelessWidget {
  const _CompactSection({
    required this.title,
    this.caption,
    this.tone = AppSectionTone.normal,
    this.trailing = AppSectionTrailing.none,
    this.trailingIcon,
    this.trailingButtonLabel,
    this.trailingWidget,
    this.onTrailingTap,
  });

  final String title;
  final String? caption;
  final AppSectionTone tone;
  final AppSectionTrailing trailing;
  final Widget? trailingIcon;
  final String? trailingButtonLabel;
  final Widget? trailingWidget;
  final VoidCallback? onTrailingTap;

  bool get _hasCaption => caption != null && caption!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final navSpec = context.appNavBarTheme.large;

    // Figma `73:2909` — title + badge sit adjacent (not space-between).
    final titleStyle = typography.regularNormal.copyWith(
      fontSize: 16.rfs,
      height: 20 / 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: tone == AppSectionTone.primary
          ? colors.primary
          : colors.palettes.dark.shade950,
    );

    return Row(
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_hasCaption) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  caption!,
                  style: typography.smallNormal.copyWith(
                    color: colors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != AppSectionTrailing.none) ...[
          SizedBox(width: responsiveSpacing(10)),
          _SectionTrailing(
            trailing: trailing,
            trailingIcon: trailingIcon,
            trailingButtonLabel: trailingButtonLabel,
            trailingWidget: trailingWidget,
            onTrailingTap: onTrailingTap,
            iconSize: navSpec.iconSize,
            iconColor: colors.textPrimary,
          ),
        ],
      ],
    );
  }
}

class _LargeSection extends StatelessWidget {
  const _LargeSection({
    required this.title,
    this.caption,
    this.trailing = AppSectionTrailing.none,
    this.trailingIcon,
    this.trailingButtonLabel,
    this.trailingWidget,
    this.onTrailingTap,
  });

  final String title;
  final String? caption;
  final AppSectionTrailing trailing;
  final Widget? trailingIcon;
  final String? trailingButtonLabel;
  final Widget? trailingWidget;
  final VoidCallback? onTrailingTap;

  bool get _hasCaption => caption != null && caption!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spec = context.appNavBarTheme.large;
    final height = _hasCaption ? spec.heightExpanded : spec.heightCompact;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _hasCaption
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: spec.titleStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        caption!,
                        style: spec.captionStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      title,
                      style: spec.titleStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          if (trailing != AppSectionTrailing.none) ...[
            SizedBox(width: AppSpacing.md),
            _SectionTrailing(
              trailing: trailing,
              trailingIcon: trailingIcon,
              trailingButtonLabel: trailingButtonLabel,
              trailingWidget: trailingWidget,
              onTrailingTap: onTrailingTap,
              iconSize: spec.iconSize,
              iconColor: colors.textPrimary,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTrailing extends StatelessWidget {
  const _SectionTrailing({
    required this.trailing,
    required this.iconSize,
    required this.iconColor,
    this.trailingIcon,
    this.trailingButtonLabel,
    this.trailingWidget,
    this.onTrailingTap,
  });

  final AppSectionTrailing trailing;
  final Widget? trailingIcon;
  final String? trailingButtonLabel;
  final Widget? trailingWidget;
  final VoidCallback? onTrailingTap;
  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return switch (trailing) {
      AppSectionTrailing.icon => GestureDetector(
          onTap: onTrailingTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: IconTheme(
              data: IconThemeData(size: iconSize, color: iconColor),
              child: trailingIcon ??
                  Icon(
                    Icons.person_outline,
                    size: iconSize,
                    color: iconColor,
                  ),
            ),
          ),
        ),
      AppSectionTrailing.button => AppButton(
          label: trailingButtonLabel ?? 'Button',
          onPressed: onTrailingTap,
          size: AppButtonSize.small,
        ),
      AppSectionTrailing.custom => trailingWidget ?? const SizedBox.shrink(),
      AppSectionTrailing.none => const SizedBox.shrink(),
    };
  }
}
