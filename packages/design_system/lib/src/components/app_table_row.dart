import 'package:design_system/src/components/app_avatar.dart';
import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/components/app_switch.dart';
import 'package:design_system/src/components/app_table_cell.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/button_tokens.dart';
import 'package:design_system/src/theme/tokens/table_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Tables` (`40:9256`).
///
/// Combinations:
/// - Leading: none / avatar / icon
/// - Caption: optional
/// - Trailing: none / text (link) / icon / small button / switch
class AppTableRow extends StatelessWidget {
  const AppTableRow({
    required this.title,
    super.key,
    this.caption,
    this.leading = AppTableLeading.none,
    this.leadingAvatar,
    this.leadingIcon,
    this.trailing = AppTableTrailing.none,
    this.trailingText,
    this.onTrailingTextTap,
    this.trailingIcon,
    this.onTrailingIconTap,
    this.trailingButtonLabel,
    this.onTrailingButton,
    this.switchValue,
    this.onSwitchChanged,
    this.switchLoading = false,
    this.onTap,
  });

  /// Primary label (`Title`).
  final String title;

  /// Optional secondary label (`Caption`).
  final String? caption;

  /// Leading slot — [AppTableLeading.none], [.avatar], or [.icon].
  final AppTableLeading leading;

  /// Custom avatar when [leading] is [AppTableLeading.avatar].
  final Widget? leadingAvatar;

  /// Custom icon when [leading] is [AppTableLeading.icon].
  final Widget? leadingIcon;

  /// Trailing slot — none / link / icon / button / switch.
  final AppTableTrailing trailing;

  /// Link label when [trailing] is [AppTableTrailing.text].
  final String? trailingText;

  final VoidCallback? onTrailingTextTap;

  /// Icon widget when [trailing] is [AppTableTrailing.icon].
  final Widget? trailingIcon;

  final VoidCallback? onTrailingIconTap;

  /// Button label when [trailing] is [AppTableTrailing.button].
  final String? trailingButtonLabel;

  final VoidCallback? onTrailingButton;

  /// Switch value when [trailing] is [AppTableTrailing.switchControl].
  final bool? switchValue;

  final ValueChanged<bool>? onSwitchChanged;

  /// Shows a spinner in the switch knob when [trailing] is
  /// [AppTableTrailing.switchControl] and a change is in flight.
  final bool switchLoading;

  /// Optional row tap (does not fire for trailing interactive controls).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spec = context.appTableTheme.row;
    final clear = colors.palettes.white.withValues(alpha: 0);

    return SizedBox(
      height: spec.height,
      width: double.infinity,
      child: Material(
        color: spec.backgroundColor,
        child: InkWell(
          onTap: onTap,
          splashFactory: onTap == null ? NoSplash.splashFactory : null,
          highlightColor: clear,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spec.horizontalPadding),
            child: Row(
              children: [
                if (leading != AppTableLeading.none) ...[
                  _buildLeading(spec),
                  SizedBox(width: spec.leadingGap),
                ],
                Expanded(
                  child: AppTableCell(
                    title: title,
                    caption: caption,
                  ),
                ),
                if (trailing != AppTableTrailing.none) ...[
                  SizedBox(width: spec.trailingGap),
                  _buildTrailing(context, spec),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(TableRowStyleSpec spec) {
    return switch (leading) {
      AppTableLeading.avatar => SizedBox(
        width: spec.avatarSize,
        height: spec.avatarSize,
        child: leadingAvatar ?? const AppAvatar(initials: 'AB'),
      ),
      AppTableLeading.icon => SizedBox(
        width: spec.leadingIconSize,
        height: spec.leadingIconSize,
        child: IconTheme(
          data: IconThemeData(
            size: spec.leadingIconSize,
            color: spec.trailingIconColor,
          ),
          child: leadingIcon ?? const Icon(Icons.circle_outlined),
        ),
      ),
      AppTableLeading.none => const SizedBox.shrink(),
    };
  }

  Widget _buildTrailing(BuildContext context, TableRowStyleSpec spec) {
    return switch (trailing) {
      AppTableTrailing.text => GestureDetector(
        onTap: onTrailingTextTap,
        behavior: HitTestBehavior.opaque,
        child: Text(
          trailingText ?? 'Link',
          style: spec.trailingTextStyle,
        ),
      ),
      AppTableTrailing.icon => GestureDetector(
        onTap: onTrailingIconTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: spec.trailingIconSize,
          height: spec.trailingIconSize,
          child: IconTheme(
            data: IconThemeData(
              color: spec.trailingIconColor,
              size: spec.trailingIconSize,
            ),
            child: trailingIcon ?? const Icon(Icons.circle_outlined),
          ),
        ),
      ),
      AppTableTrailing.button => AppButton(
        label: trailingButtonLabel ?? 'Small',
        onPressed: onTrailingButton,
        size: AppButtonSize.small,
      ),
      AppTableTrailing.switchControl => AppSwitch(
        value: switchValue ?? false,
        onChanged: onSwitchChanged,
        loading: switchLoading,
      ),
      AppTableTrailing.none => const SizedBox.shrink(),
    };
  }
}
