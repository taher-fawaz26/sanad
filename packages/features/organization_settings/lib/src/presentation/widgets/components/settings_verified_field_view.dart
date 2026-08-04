import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:organization_settings/src/presentation/widgets/components/settings_verified_badge.dart';

/// Read-only field shell with label and optional verified badge.
///
/// Wraps [child] in the standard settings field container. Used by phone and
/// email view-mode fields in general organization settings.
class SettingsVerifiedFieldView extends StatelessWidget {
  const SettingsVerifiedFieldView({
    super.key,
    required this.label,
    required this.child,
    this.showVerifiedBadge = true,
  });

  final String label;
  final Widget child;
  final bool showVerifiedBadge;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final fieldHeight = responsiveDimension(FieldTokens.fieldHeight);
    final labelGap = responsiveDimension(FieldTokens.labelGap);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            AppFieldLabel(label: label),
            if (showVerifiedBadge) ...[
              SizedBox(width: AppSpacing.xs),
              const SettingsVerifiedBadge(),
            ],
          ],
        ),
        SizedBox(height: labelGap),
        Container(
          height: fieldHeight,
          padding: EdgeInsets.symmetric(
            horizontal: responsiveDimension(FieldTokens.horizontalPadding),
          ),
          decoration: ShapeDecoration(
            color: FieldTokens.background(colors, brightness, enabled: true),
            shape: RoundedRectangleBorder(
              borderRadius: FieldTokens.borderRadiusAll(),
              side: BorderSide(
                color: FieldTokens.borderDefault(colors, brightness),
                width: responsiveDimension(FieldTokens.borderWidthDefault),
              ),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}
