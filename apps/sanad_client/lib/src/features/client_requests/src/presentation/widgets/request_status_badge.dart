import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/client_requests_tokens.dart';

/// Localized label and tone for a request status.
///
/// One mapping, used by the list row and the detail header, so the same status
/// can never read as two different things in two places.
extension ClientRequestStatusDisplay on ClientRequestStatus {
  /// The i18n key for this status.
  String get labelKey => switch (this) {
    ClientRequestStatus.draft => 'requests.status.draft',
    ClientRequestStatus.submitted => 'requests.status.submitted',
    ClientRequestStatus.scheduled => 'requests.status.scheduled',
    ClientRequestStatus.inProgress => 'requests.status.in_progress',
    ClientRequestStatus.awaitingConfirmation =>
      'requests.status.awaiting_confirmation',
    ClientRequestStatus.disputed => 'requests.status.disputed',
    ClientRequestStatus.completed => 'requests.status.completed',
    ClientRequestStatus.cancelled => 'requests.status.cancelled',
    ClientRequestStatus.expired => 'requests.status.expired',
    ClientRequestStatus.unknown => 'requests.status.unknown',
  };

  /// The badge tone for this status.
  AppStatusBadgeType get badgeType => switch (this) {
    ClientRequestStatus.completed => AppStatusBadgeType.success,
    ClientRequestStatus.scheduled ||
    ClientRequestStatus.inProgress ||
    ClientRequestStatus.submitted => AppStatusBadgeType.info,
    ClientRequestStatus.awaitingConfirmation ||
    ClientRequestStatus.draft => AppStatusBadgeType.warning,
    ClientRequestStatus.disputed ||
    ClientRequestStatus.cancelled ||
    ClientRequestStatus.expired => AppStatusBadgeType.alert,
    ClientRequestStatus.unknown => AppStatusBadgeType.info,
  };
}

/// Localized label for an offer's state.
extension RequestOfferStatusDisplay on RequestOfferStatus {
  /// The i18n key for this offer state.
  ///
  /// `lost` and `rejected` deliberately read differently: one means another
  /// provider won, the other that this offer was declined.
  String get labelKey => switch (this) {
    RequestOfferStatus.pending => 'requests.offer_status.pending',
    RequestOfferStatus.accepted => 'requests.offer_status.accepted',
    RequestOfferStatus.rejected => 'requests.offer_status.rejected',
    RequestOfferStatus.superseded => 'requests.offer_status.superseded',
    RequestOfferStatus.lost => 'requests.offer_status.lost',
    RequestOfferStatus.withdrawn => 'requests.offer_status.withdrawn',
    RequestOfferStatus.voided => 'requests.offer_status.voided',
    RequestOfferStatus.expired => 'requests.offer_status.expired',
    RequestOfferStatus.unknown => 'requests.offer_status.unknown',
  };
}

/// What a request is waiting on the **client** for, as the card's trailing
/// pill names it — Figma `missing address` (`8433:38432`).
///
/// Reads the request's own action-availability, so it can never disagree with
/// which controls the card offers. Returns `null` when the ball is not in the
/// client's court, and the pill is simply absent.
extension ClientRequestWaitingOn on ClientRequest {
  /// The i18n key for the trailing pill, or `null` for no pill.
  String? get waitingOnKey {
    if (threadsAwaitingClient.isNotEmpty) {
      return 'client_requests.waiting_your_reply';
    }
    if (canConfirmOrDispute) return 'client_requests.waiting_confirmation';
    if (!status.isDraft) return null;
    // Figma shows the location blocker; the other two say what they are
    // rather than pretending every unfinished draft is missing an address.
    final missing = missingForSubmit;
    if (missing.contains('location')) {
      return 'client_requests.missing_address';
    }
    if (missing.contains('serviceId')) {
      return 'client_requests.missing_service';
    }
    if (missing.contains('preferredAt')) return 'client_requests.missing_time';
    return null;
  }
}

/// The soft status chip at the top of a request card — Figma `8385:4393`
/// (`In Progress`), `8385:4515` (`Scheduled`), `8385:4639` (`Cancelled`).
///
/// A separate component from [RequestStatusBadge], which renders the design
/// system's four-way semantic badge (`40:10689`). This one is the Requests
/// card's own three-tone chip, and every colour it uses is an exact palette
/// step — `main/50` on `main/700`, `dark/100` on `sky/800`, `red/50` on
/// `red/500`.
class RequestStatusChip extends StatelessWidget {
  /// Creates a chip for [status].
  const RequestStatusChip({required this.status, super.key});

  /// The status to render.
  final ClientRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final palettes = colors.palettes;

    final (background, foreground) = switch (status) {
      ClientRequestStatus.scheduled => (
        palettes.dark.shade100,
        palettes.sky.shade800,
      ),
      ClientRequestStatus.disputed ||
      ClientRequestStatus.cancelled ||
      ClientRequestStatus.expired => (
        palettes.red.shade50,
        palettes.red.shade500,
      ),
      _ => (palettes.main.shade50, palettes.main.shade700),
    };

    return Container(
      height: ClientRequestsTokens.chipHeight,
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ClientRequestsTokens.chipRadius),
      ),
      // `Center(widthFactor: 1)`, not `alignment:` — a `Container` given an
      // alignment and no width expands to its whole constraint, which turned
      // Figma's label-width chip into a full-bleed bar.
      child: Center(
        widthFactor: 1,
        child: Text(
          status.labelKey.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.smallNormal.copyWith(
            fontSize: 12.rfs,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

/// A status pill for a request.
class RequestStatusBadge extends StatelessWidget {
  /// Creates a badge for [status].
  const RequestStatusBadge({required this.status, super.key});

  /// The status to render.
  final ClientRequestStatus status;

  @override
  Widget build(BuildContext context) => AppStatusBadge(
    label: status.labelKey.tr(),
    type: status.badgeType,
  );
}
