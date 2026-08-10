import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Per-service "more actions" sheet: activate/deactivate toggle + delete.
///
/// Mirrors `branches`' `showBranchActionsBottomSheet` — same
/// `SheetNavigator` + confirm-popover-before-destructive-action pattern —
/// but for the real `PATCH /services/{id}/status` and
/// `DELETE /services/{id}` endpoints via [ServiceActionBloc].
Future<void> showServiceActionsBottomSheet({
  required BuildContext context,
  required ServiceRecordEntity service,
}) {
  final bloc = context.read<ServiceActionBloc>();
  final pageContext = context;

  return SheetNavigator.push<void>(
    context,
    BlocProvider.value(
      value: bloc,
      child: _ServiceActionsSheetBody(
        service: service,
        pageContext: pageContext,
      ),
    ),
    settings: const SheetRouteSettings(
      sheetSize: SheetSize.expanded,
      padChild: false,
    ),
  );
}

class _ServiceActionsSheetBody extends StatelessWidget {
  const _ServiceActionsSheetBody({
    required this.service,
    required this.pageContext,
  });

  final ServiceRecordEntity service;
  final BuildContext pageContext;

  @override
  Widget build(BuildContext context) {
    final iconColor = context.appColors.textPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppSpacing.lg),
        AppTableRow(
          title: service.isActive
              ? 'services.action_deactivate'.tr()
              : 'services.action_activate'.tr(),
          leading: AppTableLeading.icon,
          leadingIcon: AppSvgPicture.asset(
            AppSvgs.tools,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          trailing: AppTableTrailing.switchControl,
          switchValue: service.isActive,
          onSwitchChanged: (value) => _onStatusToggled(context, value),
        ),
        const AppDivider(),
        _DeleteServiceRow(onTap: () => _onDeletePressed(context)),
      ],
    );
  }

  void _onStatusToggled(BuildContext context, bool isActive) {
    Navigator.of(context).pop();
    if (!pageContext.mounted) return;
    pageContext.read<ServiceActionBloc>().add(
      ServiceStatusToggleRequestedEvent(
        serviceId: service.id,
        isActive: isActive,
      ),
    );
  }

  Future<void> _onDeletePressed(BuildContext context) async {
    Navigator.of(context).pop();
    if (!pageContext.mounted) return;

    final confirmed = await showAppPopover<bool>(
      context: pageContext,
      title: 'services.delete_confirm_title'.tr(),
      description: 'services.delete_confirm_description'.tr(
        namedArgs: {'name': service.name},
      ),
      imageLayout: AppDialogImageLayout.iconSmall,
      featureIconColor: AppFeatureIconColor.error,
      featureIconSize: AppFeatureIconSize.lg,
      featureIconTheme: AppFeatureIconTheme.lightCircleOutline,
      primaryLabel: 'services.delete_confirm'.tr(),
      primaryDestructive: true,
      secondaryLabel: 'services.cancel'.tr(),
      onPrimary: () => Navigator.of(pageContext, rootNavigator: true).pop(true),
      onSecondary: () =>
          Navigator.of(pageContext, rootNavigator: true).pop(false),
    );

    if ((confirmed ?? false) && pageContext.mounted) {
      pageContext.read<ServiceActionBloc>().add(
        ServiceDeleteRequestedEvent(service.id),
      );
    }
  }
}

class _DeleteServiceRow extends StatelessWidget {
  const _DeleteServiceRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              AppSvgPicture.asset(AppSvgs.trash, width: 24, height: 24),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  'services.action_delete'.tr(),
                  style: typography.regularNormal.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
