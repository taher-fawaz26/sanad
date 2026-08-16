import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:services/src/domain/entities/service_request_status.dart';

/// Status-badge label/type for a [ServiceRequestStatus] — pure presentation
/// mapping, shared by `RequestDetailsPage`'s status badge and
/// `ServiceRequestListItem`'s row badge (previously duplicated identically
/// in both files).
///
/// Distinct from `ProviderServicesPage._filterLabel`, which maps the same
/// enum to different copy for the filter-chip UI (including an "All"
/// option a real request never has) — that's a genuinely different
/// presentation concern, not more of this duplication.
extension ServiceRequestStatusUi on ServiceRequestStatus {
  String get badgeLabel => switch (this) {
    ServiceRequestStatus.underReview => 'services.request_status_pending'
        .tr(),
    ServiceRequestStatus.approved => 'services.request_status_approved'.tr(),
    ServiceRequestStatus.rejected => 'services.request_status_rejected'.tr(),
    ServiceRequestStatus.all => '',
  };

  AppStatusBadgeType get badgeType => switch (this) {
    ServiceRequestStatus.underReview => AppStatusBadgeType.warning,
    ServiceRequestStatus.approved => AppStatusBadgeType.success,
    ServiceRequestStatus.rejected => AppStatusBadgeType.alert,
    ServiceRequestStatus.all => AppStatusBadgeType.warning,
  };
}
