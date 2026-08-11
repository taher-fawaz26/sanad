import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Figma confirmation body (`1526:13048`, `1526:13037`, `1526:13026`).
///
/// Shell-agnostic content — pair with a bottom sheet, modal sheet, dialog, or
/// any other container. The parent owns safe-area / bottom inset.
class AppConfirmationContent extends StatelessWidget {
  const AppConfirmationContent({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    this.actionType = AppButtonType.primary,
    this.destructive = false,
    this.padHorizontal = true,
    this.padTop = true,
    this.badge,
    super.key,
  });

  final String title;
  final String description;
  final String actionLabel;
  final String cancelLabel;
  final AppButtonType actionType;
  final bool destructive;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  /// Optional entity chip/badge rendered between [title] and [description]
  /// (e.g. the service-name pill on the delete/pause/resume/edit sheets).
  final Widget? badge;

  /// Applies [BottomSheetTokens.horizontalPadding] when hosted in a sheet.
  final bool padHorizontal;

  /// Applies post–drag-handle top spacing when hosted in a bottom sheet.
  final bool padTop;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final spec = BottomSheetTokens.resolve(
      colors: colors,
      typography: typography,
      brightness: brightness,
    );
    final sectionGap = responsiveDimension(
      BottomSheetTokens.confirmationSectionGap,
    );
    final innerGap = responsiveDimension(
      BottomSheetTokens.confirmationInnerGap,
    );
    final contentTopGap = responsiveDimension(
      BottomSheetTokens.confirmationContentTopGap,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        padHorizontal ? spec.horizontalPadding : 0,
        padTop ? contentTopGap : 0,
        padHorizontal ? spec.horizontalPadding : 0,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: typography.title2.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 32 / 24,
            ),
          ),
          if (badge != null) ...[
            SizedBox(height: AppSpacing.sm),
            Align(alignment: Alignment.centerLeft, child: badge),
          ],
          SizedBox(height: innerGap),
          Text(
            description,
            style: spec.bodyStyle.copyWith(height: 24 / 16),
          ),
          SizedBox(height: sectionGap),
          AppButton(
            label: actionLabel,
            type: actionType,
            destructive: destructive,
            onPressed: onConfirm,
          ),
          SizedBox(height: innerGap),
          AppButton(
            label: cancelLabel,
            type: AppButtonType.outline,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
