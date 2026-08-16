import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';
import 'package:services/src/presentation/mappers/service_request_status_ui.dart';
import 'package:services/src/presentation/utils/service_date_format.dart';

/// A single submitted service-request row — `GET /service-requests`,
/// Figma `4749:20349`.
///
/// Shares [ServiceListItem]'s card shell (surface/border/radius) for visual
/// consistency between the "My Services" and "Service request" tabs, but
/// the content is request-specific (category/dates instead of thumbnail +
/// revenue/requests) and — unlike [ServiceListItem] — this row has no
/// swipe actions: a request can't be edited, paused, or deleted, only
/// reviewed via "View Details".
class ServiceRequestListItem extends StatelessWidget {
  const ServiceRequestListItem({required this.request, super.key, this.onTap});

  final ServiceRequestEntity request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Material(
      color: colors.palettes.dark.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimension.radiusSm),
        side: BorderSide(color: colors.palettes.dark.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography
                          .semiBold(typography.regularNormal)
                          .copyWith(color: colors.textPrimary),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  AppStatusBadge(
                    label: request.status.badgeLabel,
                    type: request.status.badgeType,
                    size: AppStatusBadgeSize.dense,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              const AppDivider(),
              SizedBox(height: AppSpacing.lg),
              _DetailRow(
                label: 'services.request_details.category'.tr(),
                value: request.category.name,
              ),
              SizedBox(height: AppSpacing.sm),
              _DetailRow(
                label: 'services.request_details.submitted'.tr(),
                value: formatShortDate(request.createdAt),
              ),
              SizedBox(height: AppSpacing.sm),
              _DetailRow(
                label: 'services.request_details.last_update'.tr(),
                value: formatShortDate(request.updatedAt),
              ),
              if (request.status == ServiceRequestStatus.rejected &&
                  (request.rejectionReason ?? '').isNotEmpty) ...[
                SizedBox(height: AppSpacing.sm),
                Text(
                  request.rejectionReason!,
                  style: typography.smallNormal.copyWith(color: colors.error),
                ),
              ],
              if (onTap != null) ...[
                SizedBox(height: AppSpacing.lg),
                AppButtonPresets.outline(
                  label: 'services.request_details.view_details'.tr(),
                  onPressed: onTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: typography.smallNormal.copyWith(color: colors.textSecondary),
        ),
        Text(
          value,
          style: typography
              .medium(typography.smallNormal)
              .copyWith(color: colors.textPrimary),
        ),
      ],
    );
  }
}
