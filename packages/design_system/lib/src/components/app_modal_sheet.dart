import 'package:design_system/src/components/internal/overlay_drag_handle.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/bottom_sheet_tokens.dart';
import 'package:design_system/src/theme/tokens/overlay_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Near-fullscreen modal bottom sheet with a dimmed scrim overlay.
///
/// Distinct from:
/// - [showAppBottomSheet] — no scrim, content-sized
/// - [showAppActionSheet] — scrimmed, but content-sized action list
///
/// Use this for pickers, forms, or any content that needs the wizard /
/// underlying page to stay visible behind a dimmed overlay while occupying
/// most of the screen.
///
/// The sheet occupies [heightFraction] of the screen (default
/// [BottomSheetTokens.modalHeightFraction]) and includes a drag handle,
/// optional title, rounded top corners, and [SafeArea] insets.
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  double heightFraction = BottomSheetTokens.modalHeightFraction,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: OverlayTokens.scrimColor(),
    constraints: BoxConstraints(
      maxHeight:
          MediaQuery.sizeOf(context).height * heightFraction.clamp(0.5, 1.0),
    ),
    builder: (context) => _AppModalSheetContent(
      title: title,
      showDragHandle: showDragHandle,
      child: child,
    ),
  );
}

class _AppModalSheetContent extends StatelessWidget {
  const _AppModalSheetContent({
    required this.child,
    this.title,
    this.showDragHandle = true,
  });

  final Widget child;
  final String? title;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final typography = context.appTypography;
    final spec = BottomSheetTokens.resolve(
      colors: colors,
      typography: typography,
      brightness: brightness,
    );

    return Material(
      color: spec.surfaceColor,
      borderRadius: spec.topRadius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDragHandle) ...[
              SizedBox(height: spec.dragHandleTopPadding),
              OverlayDragHandle(
                width: spec.dragHandleWidth,
                height: spec.dragHandleHeight,
                color: spec.dragHandleColor,
              ),
              SizedBox(height: AppSpacing.sm),
            ],
            if (title != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spec.horizontalPadding,
                ),
                child: Text(title!, style: spec.titleStyle),
              ),
              SizedBox(height: AppSpacing.md),
            ],
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
