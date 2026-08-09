import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:services/src/domain/entities/service_entity.dart';
import 'package:shared_ui/shared_ui.dart';

/// Single-select searchable "Name of Service" picker for the Add Service
/// form.
///
/// UI-only: `services` is supplied by the caller (currently
/// `MockAddServiceData`) rather than a catalog API. Shows the
/// "Service not found" empty state with a "Request a New Service" action
/// when the search query matches nothing.
Future<ServiceEntity?> showSelectServiceNameSheet({
  required BuildContext context,
  required List<ServiceEntity> services,
  required VoidCallback onRequestNewService,
}) async {
  final selected = await showAppSelectSheet<ServiceEntity>(
    context: context,
    title: 'services.add_service.service_name_label'.tr(),
    searchHint: 'services.add_service.search_hint'.tr(),
    singleSelect: true,
    getId: (service) => service.id,
    searchFilter: (service, query) =>
        service.name.toLowerCase().contains(query),
    items: services,
    emptyBuilder: (context) => _ServiceNotFoundState(
      onRequestNewService: () {
        Navigator.of(context).pop();
        onRequestNewService();
      },
    ),
    itemBuilder: (context, service, isSelected, onTap) => AppTableRow(
      title: service.name,
      onTap: onTap,
    ),
  );
  if (selected == null || selected.isEmpty) return null;
  return selected.first;
}

class _ServiceNotFoundState extends StatelessWidget {
  const _ServiceNotFoundState({required this.onRequestNewService});

  final VoidCallback onRequestNewService;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final iconSize = responsiveDimension(48);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgPicture.asset(
              AppSvgs.searchAlert,
              width: iconSize,
              height: iconSize,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'services.add_service.not_found_title'.tr(),
              textAlign: TextAlign.center,
              style: typography
                  .semiBold(typography.regularNormal)
                  .copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'services.add_service.not_found_description'.tr(),
              textAlign: TextAlign.center,
              style: typography.smallNormal.copyWith(color: colors.textMuted),
            ),
            SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: onRequestNewService,
              child: Text(
                'services.add_service.request_new_service'.tr(),
                style: typography.smallNormal.copyWith(
                  color: colors.link,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
