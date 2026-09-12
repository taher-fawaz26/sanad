import 'package:app_animations/app_animations.dart';
import 'package:design_system/src/components/app_svg_picture.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/swipe_actions_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// One contextual action revealed by a horizontal swipe on [AppSwipeActions].
///
/// Mirrors `AppActionSheetItem`'s shape (label / callback / destructive flag)
/// so features migrating off an action-sheet menu reuse the same data.
@immutable
class AppSwipeAction {
  const AppSwipeAction({
    required this.onPressed,
    required this.semanticLabel,
    this.icon,
    this.svgAsset,
    this.label,
    this.variant = AppSwipeActionVariant.neutral,
    this.enabled = true,
    this.child,
  }) : assert(
         child != null || icon != null || svgAsset != null,
         'Provide icon, svgAsset, or a custom child.',
       );

  /// Invoked when the action is tapped. Not called when [enabled] is false.
  final VoidCallback onPressed;

  /// Required — announced by screen readers and used as the button's
  /// accessible name. Every action must remain reachable without a swipe
  /// gesture, so this label is also what the accessible fallback (e.g. the
  /// feature's existing action sheet) should continue to expose.
  final String semanticLabel;

  final IconData? icon;
  final String? svgAsset;

  /// Optional visible caption under the icon.
  final String? label;

  final AppSwipeActionVariant variant;

  /// When false, the action renders dimmed and [onPressed] is not wired.
  final bool enabled;

  /// Escape hatch for a fully custom action body. Rarely needed — prefer
  /// [icon]/[svgAsset] + [label] so styling stays token-driven.
  final Widget? child;
}

/// Reusable swipe-to-reveal-actions wrapper around an arbitrary list item.
///
/// Wraps [child] with `flutter_slidable` so features never depend on
/// `Slidable`/`ActionPane`/`SlidableAction` directly:
///
/// ```dart
/// AppSwipeActions(
///   groupTag: 'workers',
///   actions: [
///     AppSwipeAction(
///       svgAsset: AppSvgs.branchEdit,
///       semanticLabel: 'Edit',
///       onPressed: onEdit,
///     ),
///   ],
///   child: WorkerListItem(worker: worker),
/// )
/// ```
///
/// Actions are revealed on the logical **end** side, so LTR reveals on
/// swipe-left and RTL reveals on swipe-right automatically via ambient
/// [Directionality] — no locale branching. Rows sharing [groupTag] via
/// [AppSwipeActionsGroup] auto-close one another and close on scroll.
///
/// ## Two visual styles
///
/// [AppSwipeActionsStyle.separated] (the default) draws each action as its own
/// floating pill; [AppSwipeActionsStyle.grouped] draws one contiguous strip
/// clipped to the row's shape. The motion is the same either way and comes
/// from `AppSwipeActionMotion` in `app_animations` — this component owns no
/// durations of its own, and neither should its callers.
class AppSwipeActions extends StatelessWidget {
  const AppSwipeActions({
    required this.actions,
    required this.child,
    super.key,
    this.groupTag,
    this.extentRatio,
    this.controller,
    this.style = AppSwipeActionsStyle.separated,
    this.rowRadius,
  });

  final List<AppSwipeAction> actions;
  final Widget child;

  /// Rows sharing the same tag close each other when one opens, and close
  /// together when the list scrolls (via [AppSwipeActionsGroup]).
  final String? groupTag;

  /// Fraction of the row width the action pane occupies. Defaults to a
  /// per-action width so panes scale with the number of actions.
  final double? extentRatio;

  /// Externally-owned controller for programmatic control (e.g. driving a
  /// one-time swipe discoverability hint via `SwipeActionHint`). Almost
  /// always omitted — leaving it null lets `Slidable` manage its own
  /// internal controller, which is the right default for a plain row.
  final SlidableController? controller;

  /// Which of the two pane compositions to draw. See the class doc.
  final AppSwipeActionsStyle style;

  /// The wrapped row's own corner radius, so an
  /// [AppSwipeActionsStyle.grouped] pane can clip to the same shape.
  ///
  /// Ignored by [AppSwipeActionsStyle.separated], whose pills carry their own
  /// radius and never touch the row's edge.
  final double? rowRadius;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return child;

    final colors = context.appColors;
    final rowWidth = MediaQuery.sizeOf(context).width;
    final paneWidth = SwipeActionsTokens.actionWidth(style) * actions.length;
    final resolvedRatio =
        extentRatio ??
        (rowWidth > 0 ? (paneWidth / rowWidth).clamp(0.3, 1.0) : 0.6);

    return Slidable(
      key: key,
      groupTag: groupTag,
      controller: controller,
      endActionPane: ActionPane(
        // Grouped clips the whole strip as one surface; separated keeps the
        // stock motion, since its pills have nothing to clip against.
        motion: switch (style) {
          AppSwipeActionsStyle.separated => const ScrollMotion(),
          AppSwipeActionsStyle.grouped => _GroupedScrollMotion(
            rowRadius: rowRadius,
          ),
        },
        extentRatio: resolvedRatio,
        children: [
          for (final action in actions)
            _SwipeActionButton(action: action, colors: colors, style: style),
        ],
      ),
      child: child,
    );
  }
}

/// [ScrollMotion], with the whole action strip clipped to the row's shape.
///
/// `flutter_slidable` composes a pane from a `motion` widget that reads the
/// actions off the ambient `ActionPane` and lays them out itself, which is the
/// only seam where the group can be treated as one surface: the actions
/// themselves are `Expanded` flex children and cannot be wrapped individually
/// without breaking the layout they depend on.
class _GroupedScrollMotion extends StatelessWidget {
  const _GroupedScrollMotion({this.rowRadius});

  final double? rowRadius;

  @override
  Widget build(BuildContext context) {
    final paneData = ActionPane.of(context)!;
    final controller = Slidable.of(context)!;

    // Lifted verbatim from `ScrollMotion`: each child starts just outside the
    // Slidable and scrolls in with it.
    final startOffset = Offset(paneData.alignment.x, paneData.alignment.y);
    final animation = controller.animation
        .drive(CurveTween(curve: Interval(0, paneData.extentRatio)))
        .drive(Tween<Offset>(begin: startOffset, end: Offset.zero));

    return SlideTransition(
      position: animation,
      child: ClipRRect(
        borderRadius: SwipeActionsTokens.groupedBorderRadius(
          rowRadius: rowRadius,
        ).resolve(Directionality.of(context)),
        child: Flex(
          direction: paneData.direction,
          children: paneData.children,
        ),
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.action,
    required this.colors,
    required this.style,
  });

  final AppSwipeAction action;
  final AppColors colors;
  final AppSwipeActionsStyle style;

  @override
  Widget build(BuildContext context) {
    final surface = SwipeActionsTokens.resolve(
      variant: action.variant,
      colors: colors,
      enabled: action.enabled,
      style: style,
    );

    final content = action.child ?? _content(context, surface);

    final body = Semantics(
      label: action.semanticLabel,
      button: true,
      enabled: action.enabled,
      child: content,
    );

    final onPressed = action.enabled
        ? (BuildContext context) {
            Slidable.of(context)?.close();
            action.onPressed();
          }
        : (BuildContext _) {};

    return switch (style) {
      // The fill stays on an inner `Container` so the pill keeps its own
      // radius and margin inside a transparent, full-height cell.
      AppSwipeActionsStyle.separated => CustomSlidableAction(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        foregroundColor: surface.foreground,
        borderRadius: SwipeActionsTokens.borderRadius(),
        padding: EdgeInsets.zero,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: SwipeActionsTokens.actionSpacing() / 2,
          ),
          decoration: BoxDecoration(
            color: surface.background,
            borderRadius: SwipeActionsTokens.borderRadius(),
          ),
          alignment: Alignment.center,
          child: body,
        ),
      ),
      // The fill goes on the cell itself: no margin, no radius, so adjacent
      // cells butt together into one strip — and the button's own pressed
      // overlay lands *on* the fill instead of being painted under an opaque
      // Container nobody can see through, which is where the press feedback
      // used to disappear.
      AppSwipeActionsStyle.grouped => CustomSlidableAction(
        onPressed: onPressed,
        backgroundColor: surface.background,
        foregroundColor: surface.foreground,
        padding: EdgeInsets.zero,
        child: AppSwipeActionReveal(
          progress: _paneProgress(context),
          child: AppSwipeActionPress(child: body),
        ),
      ),
    };
  }

  /// The enclosing pane's `0 → 1` opening value, normalized off its own
  /// extent — the same mapping `ScrollMotion` uses to place the cells, so the
  /// contents and the surface they ride on are driven by one source.
  Animation<double> _paneProgress(BuildContext context) {
    final pane = ActionPane.of(context);
    final controller = Slidable.of(context);
    if (pane == null || controller == null) {
      return const AlwaysStoppedAnimation<double>(1);
    }
    return controller.animation.drive(
      CurveTween(curve: Interval(0, pane.extentRatio)),
    );
  }

  Widget _content(BuildContext context, SwipeActionSurfaceColors surface) {
    final iconSize = SwipeActionsTokens.iconSize(style);
    final typography = context.appTypography;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      // Figma `gap-[3px]` for the grouped cell; the separated pill keeps the
      // 4dp it shipped with.
      spacing: style == AppSwipeActionsStyle.grouped
          ? SwipeActionsTokens.contentGap()
          : 4,
      children: [
        if (action.svgAsset != null)
          AppSvgPicture.asset(
            action.svgAsset!,
            width: iconSize,
            height: iconSize,
            colorFilter: ColorFilter.mode(surface.foreground, BlendMode.srcIn),
          )
        else if (action.icon != null)
          Icon(action.icon, size: iconSize, color: surface.foreground),
        if (action.label != null)
          Text(
            action.label!,
            textAlign: TextAlign.center,
            style: typography.tinyNormal.copyWith(
              color: surface.foreground,
              fontSize: SwipeActionsTokens.labelFontSize(),
              // Figma's 18dp line applies to the grouped cell, whose caption
              // sits under a larger glyph in a taller box. The separated pill
              // keeps the tight line it shipped with.
              height: style == AppSwipeActionsStyle.grouped
                  ? SwipeActionsTokens.labelHeight
                  : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

/// Thin wrapper over [SlidableAutoCloseBehavior] so a list of
/// [AppSwipeActions] rows keeps only one pane open at a time and closes any
/// open pane when the list scrolls, without a custom controller.
///
/// Wrap the `ListView`/`CustomScrollView` that renders the swipeable rows;
/// give each [AppSwipeActions] the same [AppSwipeActions.groupTag].
class AppSwipeActionsGroup extends StatelessWidget {
  const AppSwipeActionsGroup({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SlidableAutoCloseBehavior(child: child);
  }
}
