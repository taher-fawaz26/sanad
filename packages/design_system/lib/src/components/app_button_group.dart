import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/theme/tokens/button_group_tokens.dart';
import 'package:design_system/src/theme/tokens/button_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Button Groups` (`251:6533`).
class AppButtonGroup extends StatelessWidget {
  const AppButtonGroup({
    required this.primaryLabel,
    required this.onPrimary,
    super.key,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryVariant = AppButtonVariant.primary,
    this.secondaryVariant = AppButtonVariant.secondary,
    this.primaryIntent = AppButtonIntent.standard,
    this.secondaryIntent = AppButtonIntent.standard,
    this.size = AppButtonSize.block,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final AppButtonVariant primaryVariant;
  final AppButtonVariant secondaryVariant;
  final AppButtonIntent primaryIntent;
  final AppButtonIntent secondaryIntent;
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
              variant: secondaryVariant,
              intent: secondaryIntent,
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
            variant: primaryVariant,
            intent: primaryIntent,
            size: size,
          ),
        ),
      ],
    );
  }
}
