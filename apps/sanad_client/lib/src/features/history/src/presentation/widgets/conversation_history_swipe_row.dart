import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_client/src/features/history/src/domain/conversation_history_entry.dart';
import 'package:sanad_client/src/features/history/src/presentation/conversation_history_tokens.dart';
import 'package:sanad_client/src/features/history/src/presentation/widgets/conversation_history_card.dart';

/// One history row plus the actions a swipe reveals — Figma `actions`
/// (`8487:31503`).
///
/// A thin composition over [AppSwipeActions] and nothing else. Everything
/// visual — the 64dp cells, the flush seam between them, the clip to the
/// card's corner, the reveal and press motion — belongs to the design system's
/// [AppSwipeActionsStyle.grouped] pane and to `AppSwipeActionMotion` in
/// `app_animations`. This file names *which* actions a conversation has and
/// what they mean; it does not own a duration, a curve, or a colour.
///
/// [ConversationHistoryTokens.cardRadius] is threaded through so the revealed
/// strip is clipped to the same 20dp corner the card draws, which is what
/// makes the two read as one surface sliding apart rather than a tray
/// appearing behind a card.
class ConversationHistorySwipeRow extends StatelessWidget {
  /// Creates a swipeable row for [entry].
  const ConversationHistorySwipeRow({
    required this.entry,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    super.key,
  });

  /// The conversation this row draws.
  final ConversationHistoryEntry entry;

  /// Fired when the card itself is tapped.
  final VoidCallback onTap;

  /// Fired when the destructive action is chosen. The row does not delete
  /// anything — it asks, and the screen that owns the list decides.
  final VoidCallback onDelete;

  /// Fired when the rename action is chosen.
  final VoidCallback onRename;

  /// Shared by every row on the screen so only one pane is open at a time and
  /// a scroll closes it — see [AppSwipeActionsGroup] on the list.
  static const String groupTag = 'conversation_history';

  @override
  Widget build(BuildContext context) => AppSwipeActions(
    groupTag: groupTag,
    style: AppSwipeActionsStyle.grouped,
    rowRadius: responsiveDimension(ConversationHistoryTokens.cardRadius),
    actions: [
      // Delete leads, as Figma draws it: the destructive action is the one
      // nearest the swiping thumb, and reversing the pair would put the
      // dangerous cell where muscle memory expects the safe one.
      AppSwipeAction(
        svgAsset: AppSvgs.trash,
        label: 'common.delete'.tr(),
        semanticLabel: 'common.delete'.tr(),
        variant: AppSwipeActionVariant.destructive,
        onPressed: onDelete,
      ),
      AppSwipeAction(
        svgAsset: AppSvgs.branchEdit,
        label: 'history.rename'.tr(),
        semanticLabel: 'history.rename'.tr(),
        onPressed: onRename,
      ),
    ],
    child: ConversationHistoryCard(entry: entry, onTap: onTap),
  );
}
