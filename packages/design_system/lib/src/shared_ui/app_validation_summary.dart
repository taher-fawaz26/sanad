import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Aggregate validation-error summary: a bordered block listing every
/// validation message returned for a form submission.
///
/// Failure-agnostic — callers pass pre-resolved message strings (e.g. from
/// `ValidationFailure.localizedMessages()`). Renders nothing when [messages]
/// is empty.
class AppValidationSummary extends StatelessWidget {
  const AppValidationSummary({
    required this.messages,
    super.key,
    this.title,
  });

  final List<String> messages;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();

    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.error50,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: colors.error100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            Text(
              title!,
              style: typography.regularNormal.copyWith(color: colors.error500),
            ),
            SizedBox(height: AppSpacing.xs),
          ],
          for (final message in messages)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: typography.smallNormal
                        .copyWith(color: colors.error500),
                  ),
                  Expanded(
                    child: Text(
                      message,
                      style: typography.smallNormal
                          .copyWith(color: colors.error500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
