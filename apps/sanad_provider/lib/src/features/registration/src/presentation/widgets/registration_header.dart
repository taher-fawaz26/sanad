import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Title + subtitle block used at the top of every registration step card.
class RegistrationHeader extends StatelessWidget {
  const RegistrationHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final Widget subtitle;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: typography.title2.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: responsiveDimension(AppSpacing.sm)),
        DefaultTextStyle(
          textAlign: TextAlign.center,
          style: typography.regularNormal.copyWith(color: colors.textSecondary),
          child: subtitle,
        ),
      ],
    );
  }
}
