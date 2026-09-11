import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/client_requests_tokens.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/request_date_time_picker.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/request_status_badge.dart';

/// One request, as Figma's `CardBody` draws it (`8385:4391` active,
/// `8385:4513` scheduled, `8385:31898` cancelled).
///
/// The three designs are one card with parts that come and go, not three
/// cards: same surface, same 16dp rhythm, same divider, same trailing action
/// row. What varies is driven entirely by the request itself —
///
/// * **Cancel** appears when [ClientRequest.canCancel] does.
/// * The middle row shows the **offer stack** when there are offers to show,
///   and the **date / area pills** otherwise. Figma's active card has offers
///   and its scheduled card has pills, which is the same rule seen twice.
/// * The trailing badge names what the request is waiting on, from
///   [ClientRequest.missingForSubmit] and the existing turn-taking getters —
///   Figma's `missing address` is the `location` entry of that list.
/// * **Rebook** replaces the badge once the request is closed.
///
/// Everything the card offers already existed on the detail screen; none of it
/// is a new capability, and there is deliberately no create or edit
/// affordance — a request is made by asking the agent in AI Chat.
class ClientRequestCard extends StatelessWidget {
  /// Creates a card for [request].
  const ClientRequestCard({
    required this.request,
    required this.onTap,
    super.key,
    this.onCancel,
    this.onOpenChat,
    this.onRebook,
  });

  /// The request to draw.
  final ClientRequest request;

  /// Opens the request's detail screen — offers, matched providers, confirm
  /// and dispute.
  final VoidCallback onTap;

  /// Cancels the request, or null to hide the control.
  final VoidCallback? onCancel;

  /// Opens the AI conversation, or null to hide the control — the chat
  /// surface is not reachable from every host this card renders in.
  final VoidCallback? onOpenChat;

  /// Starts a replacement request, or null to hide the control.
  final VoidCallback? onRebook;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ClientRequestsTokens.cardRadius);
    final showCancel = onCancel != null && request.canCancel;

    return DecoratedBox(
      // Outside the clip: a shadow drawn inside its own clip is invisible.
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: ClientRequestsTokens.cardShadow,
      ),
      child: Material(
        color: context.appColors.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            // Figma `CardBody`: px-20 py-16, 16dp between blocks.
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.lg,
              children: [
                _HeaderRow(
                  status: request.status,
                  onCancel: showCancel ? onCancel : null,
                ),
                _TextStack(request: request),
                _MiddleRow(request: request),
                Divider(
                  height: 0,
                  thickness: AppDimension.borderHairline,
                  color: ClientRequestsTokens.divider,
                ),
                _ActionsRow(
                  request: request,
                  onOpenChat: onOpenChat,
                  onRebook: onRebook,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Status chip on the leading edge, Cancel on the trailing one — Figma
/// `8433:38437`.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.status, required this.onCancel});

  final ClientRequestStatus status;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => Row(
    spacing: AppSpacing.lg,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: RequestStatusChip(status: status),
        ),
      ),
      // `Flexible`, not a fixed width: at 360dp with a long translation or a
      // large text scale, the button and the status chip together can ask for
      // more than the card has. Both give width back rather than overflowing.
      if (onCancel != null)
        Flexible(
          child: _OutlineAction(
            label: 'client_requests.cancel'.tr(),
            color: ClientRequestsTokens.danger,
            onTap: onCancel!,
          ),
        ),
    ],
  );
}

/// Title over description — Figma `Text_Stack` (`8385:4395`).
class _TextStack extends StatelessWidget {
  const _TextStack({required this.request});

  final ClientRequest request;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final subtitle = _subtitle(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Text(
          // A draft may legitimately have no service yet. It names itself
          // rather than borrowing the picker's *placeholder* — a row reading
          // "Choose a service" looks like a request the user named that.
          request.serviceName ?? 'client_requests.untitled_draft'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.regularNormal.copyWith(
            fontSize: 16.rfs,
            fontWeight: FontWeight.w700,
            color: ClientRequestsTokens.cardTitle,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            // Figma wraps to two lines and stops (`8385:4397`).
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: typography.smallNormal.copyWith(
              fontSize: 13.rfs,
              height: 16 / 13,
              color: ClientRequestsTokens.cardBody,
            ),
          ),
      ],
    );
  }

  /// Figma's second line is `Aug 28 · Furniture Relocation Request - Palm
  /// Jumeirah` — a date, the client's own description, and where. Built from
  /// whichever of those the request actually has rather than printing empty
  /// separators around missing ones.
  String? _subtitle(BuildContext context) {
    final when = request.scheduledAt ?? request.preferredAt;
    final parts = [
      if (when != null) formatRequestDate(context, when),
      if (request.note != null && request.note!.trim().isNotEmpty)
        request.note!.trim()
      else if (request.categoryName != null)
        request.categoryName!,
      if (request.areaName != null) request.areaName!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// The offer stack, or the date / area pills — Figma `Card_Middle_Row`
/// (`8385:4398`) and `8385:4520`.
class _MiddleRow extends StatelessWidget {
  const _MiddleRow({required this.request});

  final ClientRequest request;

  @override
  Widget build(BuildContext context) {
    if (request.offerCount > 0) return _OffersRow(request: request);

    final when = request.scheduledAt ?? request.preferredAt;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        if (when != null)
          _MetaPill(
            icon: AppSvgs.requestCalendar,
            label: formatRequestDayAndDate(context, when),
          ),
        if (request.areaName != null)
          _MetaPill(
            icon: AppSvgs.requestAreaArrow,
            label: request.areaName!,
          ),
      ],
    );
  }
}

/// Overlapping provider avatars plus the offer count — Figma `Avatars_Group`
/// (`8385:4399`).
class _OffersRow extends StatelessWidget {
  const _OffersRow({required this.request});

  final ClientRequest request;

  /// Figma draws three portraits and then a `+N` chip.
  static const _maxFaces = 3;

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((word) => word.isEmpty);
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words[1].substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final faces = request.matchedBranches.take(_maxFaces).toList();
    final overflow = request.offerCount - faces.length;

    return Row(
      children: [
        if (faces.isNotEmpty)
          AppAvatarStack(
            tone: AppAvatarStackTone.success,
            maxVisible: _maxFaces,
            overflowCount: overflow > 0 ? overflow : 0,
            avatars: [
              // The matched-branch payload carries a name, not a logo, so
              // the stack shows initials rather than a broken image slot.
              for (final branch in faces)
                AppAvatar(initials: _initials(branch.branchName)),
            ],
          ),
        if (faces.isNotEmpty) SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${request.offerCount} ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: 'client_requests.offers_label'.tr(),
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.smallNormal.copyWith(
              fontSize: 14.rfs,
              color: ClientRequestsTokens.cardBody,
            ),
          ),
        ),
      ],
    );
  }
}

/// A bordered icon + value pill — Figma `8385:4521`.
class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    // `#262E32` / `#C4D3DB` — `sky/900` and `sky/300` exactly.
    final ink = colors.palettes.sky.shade900;

    return Container(
      height: ClientRequestsTokens.metaPillHeight,
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ClientRequestsTokens.metaPillRadius,
        ),
        border: Border.all(
          color: colors.palettes.sky.shade300,
          width: AppDimension.borderHairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          AppSvgPicture.asset(
            icon,
            width: ClientRequestsTokens.metaPillIcon,
            height: ClientRequestsTokens.metaPillIcon,
            colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.smallNormal.copyWith(
              fontSize: 14.rfs,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Open Chat ↗" on the leading edge; what the request is waiting on, or
/// Rebook, on the trailing one — Figma `ActionsRow` (`8385:4409`).
class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.request,
    required this.onOpenChat,
    required this.onRebook,
  });

  final ClientRequest request;
  final VoidCallback? onOpenChat;
  final VoidCallback? onRebook;

  @override
  Widget build(BuildContext context) {
    final waitingOn = request.waitingOnKey;
    final showRebook = onRebook != null && request.status.isClosed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: AppSpacing.sm,
      children: [
        if (onOpenChat != null)
          Flexible(
            child: _TextAction(
              label: 'client_requests.open_chat'.tr(),
              icon: Icons.arrow_outward_rounded,
              onTap: onOpenChat!,
            ),
          )
        else
          const SizedBox.shrink(),
        // Both ends are flexible and `spaceBetween` does the spreading: a
        // `Spacer` plus an inflexible trailing control overflows the moment
        // the two labels together exceed the row.
        if (showRebook)
          Flexible(
            child: _OutlineAction(
              label: 'client_requests.rebook'.tr(),
              color: ClientRequestsTokens.action,
              icon: Icons.refresh_rounded,
              onTap: onRebook!,
            ),
          )
        else if (waitingOn != null)
          Flexible(child: _WaitingBadge(label: waitingOn.tr()))
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

/// The amber "missing address" pill — Figma `status-badge` (`8433:38432`).
class _WaitingBadge extends StatelessWidget {
  const _WaitingBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      height: ClientRequestsTokens.badgeHeight,
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        // `#FFEED7` on `#212324` — `yellow/100` and `dark/900` exactly.
        color: colors.palettes.yellow.shade100,
        borderRadius: BorderRadius.circular(ClientRequestsTokens.chipRadius),
      ),
      // `Center(widthFactor: 1)`, not `alignment:` — see `RequestStatusChip`.
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.smallNormal.copyWith(
            fontSize: 12.rfs,
            fontWeight: FontWeight.w500,
            color: colors.palettes.dark.shade900,
          ),
        ),
      ),
    );
  }
}

/// A label + glyph rendered as a link, not a button — Figma `Open Chat ↗`.
class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.circularSm,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xs,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.smallNormal.copyWith(
                    fontSize: 14.rfs,
                    fontWeight: FontWeight.w600,
                    color: ClientRequestsTokens.action,
                  ),
                ),
              ),
              // Figma writes the arrow as a literal `↗`, which points out of
              // the *page*, not out of the text. Under RTL that reading
              // reverses, so the glyph is a widget and mirrors with the row
              // rather than being frozen into the string.
              Icon(
                icon,
                size: AppDimension.iconCompact,
                color: ClientRequestsTokens.action,
                textDirection: Directionality.of(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A hairline pill button — Figma `CancelButton` (`8433:38470`) and
/// `RebookButton` (`8385:4663`), which differ only in colour and glyph.
class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final radius = BorderRadius.circular(ClientRequestsTokens.buttonRadius);

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            height: ClientRequestsTokens.chipHeight,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: color,
                width: AppDimension.borderHairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.xs,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.smallNormal.copyWith(
                      fontSize: 13.rfs,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(icon, size: AppDimension.iconXs, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
