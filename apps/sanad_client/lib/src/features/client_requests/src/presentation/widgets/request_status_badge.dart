import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:requests_core/requests_core.dart';

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
