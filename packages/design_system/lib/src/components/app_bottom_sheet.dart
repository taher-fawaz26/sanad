import 'package:design_system/src/components/internal/overlay_drag_handle.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/bottom_sheet_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Bottom Sheets` (`40:9140`).
///
/// A bottom sheet slides up over the current screen **without** a dimming
/// scrim. This is intentionally different from:
/// - [AppActionSheet] — uses a dark barrier (`_Partials/Overlay`)
/// - [AppBackdrop] — stacked front/back sheets (Figma `40:9149`)
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    this.title,
    this.child,
    this.showDragHandle = true,
    this.padChild = true,
  });

  final String? title;
  final Widget? child;
  final bool showDragHandle;

  /// When `true` (default), applies [BottomSheetTokens] horizontal padding
  /// around [child]. Set to `false` for edge-to-edge rows (e.g. table menus).
  final bool padChild;

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
    final bottomInset =
        AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom;

    return Material(
      color: spec.surfaceColor,
      borderRadius: spec.topRadius,
      clipBehavior: Clip.antiAlias,
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
          ] else if (title == null)
            SizedBox(height: AppSpacing.xxl),
          if (title != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spec.horizontalPadding,
              ),
              child: Text(title!, style: spec.titleStyle),
            ),
          if (title != null && child != null) SizedBox(height: AppSpacing.lg),
          if (child != null)
            Padding(
              padding: padChild
                  ? EdgeInsets.fromLTRB(
                      spec.horizontalPadding,
                      0,
                      spec.horizontalPadding,
                      bottomInset,
                    )
                  : EdgeInsets.only(bottom: bottomInset),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// Shows a Figma-styled bottom sheet **without** a dimming overlay.
///
/// Matches `Views / Bottom Sheets` (`40:9140`). For a scrimmed modal list
/// of actions, use [showAppActionSheet] instead.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  String? title,
  Widget? child,
  bool isDismissible = true,
  bool showDragHandle = true,
  bool padChild = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    // Figma bottom sheets have no barrier/scrim — unlike action sheets.
    barrierColor: Colors.transparent,
    builder: (context) => AppBottomSheet(
      title: title,
      showDragHandle: showDragHandle,
      padChild: padChild,
      child: child,
    ),
  );
}
