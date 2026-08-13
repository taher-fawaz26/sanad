import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Centered loading indicator with an optional message.
///
/// Use for full-page or full-sliver loading states with no structural
/// content to skeletonize. For list/detail skeletons, prefer
/// `AppSkeletonizer`/`AppSkeletonList` (`shared_ui/src/loading/`) instead.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message});

  /// Optional supporting text shown under the indicator.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoadingIndicator(),
          if (message != null) ...[
            SizedBox(height: AppSpacing.md),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.appTypography.regularNormal.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
