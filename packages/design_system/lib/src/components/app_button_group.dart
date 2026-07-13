import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/theme/tokens/button_group_tokens.dart';
import 'package:design_system/src/theme/tokens/button_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Button Groups` (`251:6533`).
class AppButtonGroup extends StatelessWidget {
  const AppButtonGroup({
    required this.primaryLabel, required this.onPrimary, super.key,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryType = AppButtonType.primary,
    this.secondaryType = AppButtonType.secondary,
    this.size = AppButtonSize.block,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final AppButtonType primaryType;
  final AppButtonType secondaryType;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    final spec = ButtonGroupTokens.resolve();

    return Row(
      children: [
        if (secondaryLabel != null) ...[
          Expanded(
            flex: spec.buttonFlex,
            child: AppButton(
              label: secondaryLabel!,
              onPressed: onSecondary,
              type: secondaryType,
              size: size,
            ),
          ),
          SizedBox(width: spec.gap),
        ],
        Expanded(
          flex: spec.buttonFlex,
          child: AppButton(
            label: primaryLabel,
            onPressed: onPrimary,
            type: primaryType,
            size: size,
          ),
        ),
      ],
    );
  }
}
