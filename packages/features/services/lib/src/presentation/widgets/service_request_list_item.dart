import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';

/// A single submitted service-request row — `GET /service-requests/mine`.
class ServiceRequestListItem extends StatelessWidget {
  const ServiceRequestListItem({required this.request, super.key});

  final ServiceRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        border: Border.all(color: colors.palettes.sky.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography
                      .semiBold(typography.regularNormal)
                      .copyWith(color: colors.textPrimary),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              AppStatusBadge(
                label: _statusLabel(request.status),
                type: _statusType(request.status),
                size: AppStatusBadgeSize.dense,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            request.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: typography.smallNormal.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (request.status == ServiceRequestStatus.rejected &&
              (request.rejectionReason ?? '').isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              request.rejectionReason!,
              style: typography.smallNormal.copyWith(color: colors.error),
            ),
          ],
        ],
      ),
    );
  }

  static String _statusLabel(ServiceRequestStatus status) => switch (status) {
    ServiceRequestStatus.pending => 'services.request_status_pending'.tr(),
    ServiceRequestStatus.approved => 'services.request_status_approved'.tr(),
    ServiceRequestStatus.rejected => 'services.request_status_rejected'.tr(),
  };

  static AppStatusBadgeType _statusType(ServiceRequestStatus status) =>
      switch (status) {
        ServiceRequestStatus.pending => AppStatusBadgeType.warning,
        ServiceRequestStatus.approved => AppStatusBadgeType.success,
        ServiceRequestStatus.rejected => AppStatusBadgeType.alert,
      };
}
