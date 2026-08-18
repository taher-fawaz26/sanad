import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/presentation/models/provider_service_card_data.dart';
import 'package:services/src/presentation/widgets/service_action_invokers.dart';

/// Swipe-group tag shared by every [ServiceListItem] so only one row's swipe
/// actions stay open at a time — wrap the list in `AppSwipeActionsGroup`.
const serviceSwipeGroupTag = 'services';

const _thumbnailSize = 54.0;

/// Compact My-Services row — Figma `service-row` reference.
///
/// Contextual actions (Edit / Pause-Resume / Delete) are exposed only via
/// swipe-to-reveal (`AppSwipeActions`) — there is no secondary "more" menu
/// on this row. All actions call the exact same `ServiceActionBloc` events
/// via `service_action_invokers.dart`.
///
/// The three swipes are ALL owner-only mutations: `PATCH /provider-services/
/// :id[/status]` and `DELETE /provider-services/:id` (RBAC Phase 7 finding
/// G3 — no permission exists for any of these writes, so a persona check is
/// the only correct client gate). When [isOwner] is false, the row still
/// renders (a manager holding `provider:provider-service:view` legitimately
/// sees the list) but with no swipe actions attached — matching the plan's
/// "the app must NOT present controls whose tap immediately bounces" rule.
class ServiceListItem extends StatelessWidget {
  const ServiceListItem({
    required this.service,
    super.key,
    this.onTap,
    this.isOwner = true,
  });

  final ProviderServiceEntity service;
  final VoidCallback? onTap;

  /// Whether to expose the swipe actions (Edit / Pause-Resume / Delete).
  /// Defaults to `true` for backwards compatibility with any consumer that
  /// doesn't yet thread `isOwner` in.
  final bool isOwner;

  bool get _isActive => service.status == ProviderServiceStatus.active;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final data = ProviderServiceCardData.fromEntity(service);
    final thumbnailSize = responsiveDimension(_thumbnailSize);
    final radius = BorderRadius.circular(AppDimension.radiusSm);

    return AppSwipeActions(
      groupTag: serviceSwipeGroupTag,
      actions: isOwner
          ? [
              AppSwipeAction(
                icon: Icons.edit_outlined,
                semanticLabel: 'services.action_edit'.tr(),
                onPressed: () =>
                    editService(context: context, service: service),
              ),
              AppSwipeAction(
                icon: _isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                semanticLabel: _isActive
                    ? 'services.action_pause'.tr()
                    : 'services.action_resume'.tr(),
                variant: _isActive
                    ? AppSwipeActionVariant.warning
                    : AppSwipeActionVariant.primary,
                onPressed: () => confirmAndToggleServiceStatus(
                  context: context,
                  service: service,
                ),
              ),
              AppSwipeAction(
                svgAsset: AppSvgs.trash,
                semanticLabel: 'services.action_delete'.tr(),
                variant: AppSwipeActionVariant.destructive,
                onPressed: () => confirmAndDeleteService(
                  context: context,
                  service: service,
                ),
              ),
            ]
          : const [],
      child: Material(
        color: colors.palettes.dark.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colors.palettes.dark.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppNetworkImage(
                  data.coverImageUrl ?? '',
                  width: thumbnailSize,
                  height: thumbnailSize,
                  borderRadius: BorderRadius.circular(AppDimension.radiusSm),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: typography
                                  .semiBold(typography.regularNormal)
                                  .copyWith(color: colors.textPrimary),
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          AppStatusBadge(
                            label: data.statusLabel,
                            type: data.isActive
                                ? AppStatusBadgeType.success
                                : AppStatusBadgeType.warning,
                            size: AppStatusBadgeSize.dense,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: _MetricColumn(
                              label: 'services.card_revenue'.tr(),
                              value: data.revenueLabel,
                            ),
                          ),
                          SizedBox(width: AppSpacing.xl),
                          Flexible(
                            child: _MetricColumn(
                              label: 'services.card_requests'.tr(),
                              value: data.requestsCount,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.tinyNormal.copyWith(color: colors.textSecondary),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography
              .semiBold(typography.smallTight)
              .copyWith(color: colors.primary),
        ),
      ],
    );
  }
}
