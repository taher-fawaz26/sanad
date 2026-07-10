import 'package:design_system/src/components/app_avatar.dart';
import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/components/app_switch.dart';
import 'package:design_system/src/components/app_table_cell.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/button_tokens.dart';
import 'package:design_system/src/theme/tokens/table_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Tables` (`40:9256`).
class AppTableRow extends StatelessWidget {
  const AppTableRow({
    required this.title, super.key,
    this.caption,
    this.leading = AppTableLeading.none,
    this.leadingAvatar,
    this.leadingIcon,
    this.trailing = AppTableTrailing.none,
    this.trailingText,
    this.onTrailingTextTap,
    this.trailingIcon,
    this.trailingButtonLabel,
    this.onTrailingButton,
    this.switchValue,
    this.onSwitchChanged,
    this.onTap,
  });

  final String title;
  final String? caption;
  final AppTableLeading leading;
  final Widget? leadingAvatar;
  final Widget? leadingIcon;
  final AppTableTrailing trailing;
  final String? trailingText;
  final VoidCallback? onTrailingTextTap;
  final Widget? trailingIcon;
  final String? trailingButtonLabel;
  final VoidCallback? onTrailingButton;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spec = context.appTableTheme.row;
    final clear = colors.palettes.white.withValues(alpha: 0);

    return SizedBox(
      height: spec.height,
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
      AppTableLeading.avatar =>
        leadingAvatar ?? const AppAvatar(initials: 'AB'),
      AppTableLeading.icon => SizedBox(
          width: spec.leadingIconSize,
          height: spec.leadingIconSize,
          child: leadingIcon,
        ),
      AppTableLeading.none => const SizedBox.shrink(),
    };
  }

  Widget _buildTrailing(BuildContext context, TableRowStyleSpec spec) {
    return switch (trailing) {
      AppTableTrailing.text => GestureDetector(
          onTap: onTrailingTextTap,
          child: Text(
            trailingText ?? 'Link',
            style: spec.trailingTextStyle,
          ),
        ),
      AppTableTrailing.icon => SizedBox(
          width: spec.leadingIconSize,
          height: spec.leadingIconSize,
          child: IconTheme(
            data: IconThemeData(
              color: spec.trailingIconColor,
              size: spec.leadingIconSize,
            ),
            child: trailingIcon ?? const Icon(Icons.chevron_right),
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
        ),
      AppTableTrailing.none => const SizedBox.shrink(),
    };
  }
}
