import 'package:design_system/src/components/internal/overlay_drag_handle.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/bottom_sheet_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Bottom Sheets` (`40:9140`) and `Backdrops` (`40:9149`).
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    this.title,
    this.child,
    this.showDragHandle = true,
  });

  final String? title;
  final Widget? child;
  final bool showDragHandle;

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

    return Container(
      decoration: BoxDecoration(
        color: spec.surfaceColor,
        borderRadius: spec.topRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDragHandle) ...[
            SizedBox(height: spec.dragHandleTopPadding),
            OverlayDragHandle(
              width: spec.dragHandleWidth,
              height: spec.dragHandleHeight,
              color: spec.dragHandleColor,
            ),
            SizedBox(height: AppSpacing.lg),
          ],
          if (title != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spec.horizontalPadding,
              ),
              child: Text(title!, style: spec.titleStyle),
            ),
          if (title != null && child != null)
            SizedBox(height: AppSpacing.lg),
          if (child != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                spec.horizontalPadding,
                0,
                spec.horizontalPadding,
                AppSpacing.xxl,
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// Shows a Figma-styled modal bottom sheet.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  String? title,
  Widget? child,
  bool isDismissible = true,
  bool showDragHandle = true,
}) {
  final colors = context.appColors;
  final typography = context.appTypography;
  final brightness = Theme.of(context).brightness;
  final spec = BottomSheetTokens.resolve(
    colors: colors,
    typography: typography,
    brightness: brightness,
  );

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    barrierColor: spec.barrierColor,
    builder: (context) => AppBottomSheet(
      title: title,
      showDragHandle: showDragHandle,
      child: child,
    ),
  );
}
