import 'package:design_system/src/components/app_svg_picture.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/swipe_actions_tokens.dart';
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
class AppSwipeActions extends StatelessWidget {
  const AppSwipeActions({
    required this.actions,
    required this.child,
    super.key,
    this.groupTag,
    this.extentRatio,
  });

  final List<AppSwipeAction> actions;
  final Widget child;

  /// Rows sharing the same tag close each other when one opens, and close
  /// together when the list scrolls (via [AppSwipeActionsGroup]).
  final String? groupTag;

  /// Fraction of the row width the action pane occupies. Defaults to a
  /// per-action width so panes scale with the number of actions.
  final double? extentRatio;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return child;

    final colors = context.appColors;
    final rowWidth = MediaQuery.sizeOf(context).width;
    final paneWidth = SwipeActionsTokens.actionWidth() * actions.length;
    final resolvedRatio =
        extentRatio ??
        (rowWidth > 0 ? (paneWidth / rowWidth).clamp(0.3, 1.0) : 0.6);

    return Slidable(
      key: key,
      groupTag: groupTag,
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: resolvedRatio,
        children: [
          for (final action in actions)
            _SwipeActionButton(action: action, colors: colors),
        ],
      ),
      child: child,
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({required this.action, required this.colors});

  final AppSwipeAction action;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final surface = SwipeActionsTokens.resolve(
      variant: action.variant,
      colors: colors,
      enabled: action.enabled,
    );
    final iconSize = SwipeActionsTokens.iconSize();
    final radius = SwipeActionsTokens.borderRadius();
    final spacing = SwipeActionsTokens.actionSpacing();

    final content =
        action.child ??
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (action.svgAsset != null)
              AppSvgPicture.asset(
                action.svgAsset!,
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(
                  surface.foreground,
                  BlendMode.srcIn,
                ),
              )
            else if (action.icon != null)
              Icon(action.icon, size: iconSize, color: surface.foreground),
            if (action.label != null) ...[
              const SizedBox(height: 4),
              Text(
                action.label!,
                style: TextStyle(color: surface.foreground, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );

    return CustomSlidableAction(
      onPressed: action.enabled
          ? (context) {
              Slidable.of(context)?.close();
              action.onPressed();
            }
          : (_) {},
      backgroundColor: Colors.transparent,
      foregroundColor: surface.foreground,
      borderRadius: radius,
      padding: EdgeInsets.zero,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: spacing / 2),
        decoration: BoxDecoration(
          color: surface.background,
          borderRadius: radius,
        ),
        alignment: Alignment.center,
        child: Semantics(
          label: action.semanticLabel,
          button: true,
          enabled: action.enabled,
          child: content,
        ),
      ),
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
