import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:sheet_navigation/src/route/sheet_size.dart';

/// Passive chrome for sheet content: rounded top corners, drag handle,
/// optional title, safe-area, and keyboard-inset padding.
///
/// Owns no animation or gesture logic — `ModalSheetRoute` drives the
/// slide/morph transform and the height constraints around this widget, and
/// attaches the drag gesture to [onVerticalDragStart],
/// [onVerticalDragUpdate], [onVerticalDragEnd].
///
/// [sheetSize] controls how the content area fills the space it's given:
/// [SheetSize.content] lets [child] size to its own natural height (so a
/// short menu doesn't stretch to fill the screen); [SheetSize.expanded]
/// forces [child] to fill all remaining height (for long forms/search/OTP).
/// The actual height range for content sizing is enforced by the caller
/// (typically `ModalSheetRoute`, via a `ConstrainedBox`) — this widget only
/// decides whether to *fill* or *wrap* within whatever height it's given.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    required this.child,
    super.key,
    this.title,
    this.trailing,
    this.sheetSize = SheetSize.content,
    this.showDragHandle = true,
    this.useSafeArea = true,
    this.radius = const BorderRadius.vertical(top: Radius.circular(16)),
    this.enableDrag = true,
    this.padChild = true,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final SheetSize sheetSize;
  final bool showDragHandle;
  final bool useSafeArea;
  final BorderRadius radius;
  final bool enableDrag;

  /// When `true` (default), applies the design system's horizontal padding
  /// around [child]. Set to `false` for edge-to-edge content (e.g. a menu
  /// of full-width rows).
  final bool padChild;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

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

    Widget content = Material(
      color: spec.surfaceColor,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDragHandle || title != null || trailing != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: enableDrag ? onVerticalDragStart : null,
                onVerticalDragUpdate: enableDrag ? onVerticalDragUpdate : null,
                onVerticalDragEnd: enableDrag ? onVerticalDragEnd : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showDragHandle) ...[
                      SizedBox(height: spec.dragHandleTopPadding),
                      Center(
                        child: Container(
                          width: spec.dragHandleWidth,
                          height: spec.dragHandleHeight,
                          decoration: BoxDecoration(
                            color: spec.dragHandleColor,
                            borderRadius: BorderRadius.circular(
                              spec.dragHandleHeight / 2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                    ],
                    if (title != null || trailing != null)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: spec.horizontalPadding,
                        ),
                        child: Row(
                          children: [
                            if (title != null)
                              Expanded(
                                child: Text(title!, style: spec.titleStyle),
                              ),
                            if (trailing != null) trailing!,
                          ],
                        ),
                      ),
                    if (title != null) SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            Flexible(
              fit: sheetSize == SheetSize.expanded
                  ? FlexFit.tight
                  : FlexFit.loose,
              child: padChild
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: spec.horizontalPadding,
                      ),
                      child: child,
                    )
                  : child,
            ),
          ],
        ),
      ),
    );

    if (useSafeArea) {
      content = SafeArea(top: false, child: content);
    }
    return content;
  }
}
