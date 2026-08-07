import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:services/src/domain/entities/service_entity.dart';
import 'package:services/src/domain/usecases/get_services_usecase.dart';
import 'package:shared_ui/shared_ui.dart';

/// Result returned when the user confirms service selection.
class SelectServiceResult {
  const SelectServiceResult({required this.selectedServices});

  final List<ServiceEntity> selectedServices;
}

/// Figma `assign service` action sheet (`251:7195`).
///
/// Loads services from [GetServicesUseCase], supports multi-select with search,
/// and returns the confirmed selection.
Future<SelectServiceResult?> showSelectServiceActionSheet({
  required BuildContext context,
  Set<String> initialSelectedIds = const {},
}) async {
  final selected = await showAppSelectSheet<ServiceEntity>(
    context: context,
    title: 'services.select_service.title'.tr(),
    confirmLabel: 'services.select_service.confirm'.tr(),
    searchHint: 'services.select_service.search_hint'.tr(),
    searchVariant: AppSearchFieldVariant.bordered,
    getId: (s) => s.id,
    searchFilter: (s, q) =>
        s.name.toLowerCase().contains(q) ||
        s.category.toLowerCase().contains(q),
    initialSelectedIds: initialSelectedIds,
    loadItems: () async {
      final result = await sl<GetServicesUseCase>()(const NoParams()).run();
      return result.fold((f) => throw f, (services) => services);
    },
    errorTextBuilder: (e) => e is Failure ? e.message : e.toString(),
    retryLabel: 'services.select_service.retry'.tr(),
    emptyBuilder: (context) => _ServiceEmptyState(),
    itemBuilder: (context, service, isSelected, onTap) => AppTableRow(
      title: service.name,
      trailing: AppTableTrailing.icon,
      trailingIcon: AppCheckbox(
        value: isSelected,
        onChanged: (_) => onTap(),
      ),
      onTap: onTap,
    ),
  );
  if (selected == null) return null;
  return SelectServiceResult(selectedServices: selected);
}

class _ServiceEmptyState extends StatelessWidget {
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
              'services.select_service.empty'.tr(),
              textAlign: TextAlign.center,
              style: typography
                  .semiBold(typography.regularNormal)
                  .copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'services.select_service.empty_description'.tr(),
              textAlign: TextAlign.center,
              style: typography.smallNormal.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
