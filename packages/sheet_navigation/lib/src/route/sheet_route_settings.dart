import 'package:flutter/material.dart';
import 'package:sheet_navigation/src/route/sheet_size.dart';

export 'package:sheet_navigation/src/route/sheet_size.dart';

/// Presentation configuration for a `ModalSheetRoute`.
///
/// Immutable value object — the single knob-set for how a sheet looks and
/// behaves. Defaults produce a content-sized, dismissible, draggable sheet
/// that expands the previous sheet to fullscreen when pushed on top of it.
@immutable
class SheetRouteSettings {
  const SheetRouteSettings({
    this.sheetSize = SheetSize.content,
    this.initialHeightFraction,
    this.snapFractions = const [0.92],
    this.minHeight,
    this.maxHeightFactor = 0.92,
    this.isDismissible = true,
    this.enableDrag = true,
    this.expandPreviousToFullscreen = true,
    this.barrierColor,
    this.useSafeArea = true,
    this.restorationId,
    this.title,
    this.padChild = true,
  }) : assert(
         maxHeightFactor > 0 && maxHeightFactor <= 1,
         'maxHeightFactor must be in (0, 1]',
       );

  /// Whether the sheet wraps its content ([SheetSize.content], the default)
  /// or fills a fixed fraction of the screen regardless of content
  /// ([SheetSize.expanded]).
  final SheetSize sheetSize;

  /// [SheetSize.expanded] only: height fraction of the screen the sheet
  /// occupies on entry. `null` means the largest [snapFractions] entry.
  final double? initialHeightFraction;

  /// [SheetSize.expanded] only: ascending snap points (as screen-height
  /// fractions) the sheet settles to after a drag gesture. Must be
  /// non-empty.
  final List<double> snapFractions;

  /// [SheetSize.content] only: floor on the sheet's height (logical pixels)
  /// so very small content doesn't render as a tiny floating card. `null`
  /// means no floor beyond the content's own natural size.
  final double? minHeight;

  /// [SheetSize.content] only: ceiling on the sheet's height, as a fraction
  /// of the screen height. Content taller than this scrolls within the
  /// sheet (the caller's content is expected to be scrollable) rather than
  /// growing the sheet past it.
  final double maxHeightFactor;

  /// Whether tapping the scrim barrier dismisses the sheet.
  final bool isDismissible;

  /// Whether the sheet can be dragged (to dismiss or to snap).
  final bool enableDrag;

  /// Whether the previous route (if it is also a `ModalSheetRoute`) morphs to
  /// fullscreen while this route is on top of it.
  final bool expandPreviousToFullscreen;

  /// Barrier color. Defaults to `OverlayTokens.scrimColor` when null.
  final Color? barrierColor;

  /// Whether sheet content is wrapped in a [SafeArea].
  final bool useSafeArea;

  /// Optional restoration id forwarded to the underlying route.
  final String? restorationId;

  /// Optional title rendered above the sheet content, next to the drag
  /// handle (forwarded to `SheetScaffold`).
  final String? title;

  /// Forwarded to `SheetScaffold.padChild`.
  final bool padChild;

  double get largestSnapFraction =>
      snapFractions.isEmpty ? 1.0 : snapFractions.last;
}
