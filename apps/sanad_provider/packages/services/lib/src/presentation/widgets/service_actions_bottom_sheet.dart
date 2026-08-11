import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/widgets/service_confirmation_sheet.dart';
import 'package:services/src/routes/service_routes.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Per-service "more actions" sheet — Figma `5261:44521` (active) /
/// `5261:44579` (paused): Edit Service / Pause-or-Resume Service / Delete
/// Service as three tappable rows, each guarded by its own confirmation
/// sheet.
///
/// Reuses [ServiceActionBloc] for the real `PATCH /services/{id}/status` and
/// `DELETE /services/{id}` endpoints; "Edit Service" navigates to
/// `EditServicePage` (`PATCH /services/{id}`) and re-broadcasts the result
/// via [ServiceExternallyUpdatedEvent] so both the dashboard list and the
/// details page fold it in the same way.
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
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppSpacing.lg),
        _ServiceActionRow(
          label: 'services.action_edit'.tr(),
          icon: Icons.edit_outlined,
          color: colors.textPrimary,
          onTap: () => _onEditPressed(context),
        ),
        const AppDivider(),
        _ServiceActionRow(
          label: service.isActive
              ? 'services.action_pause'.tr()
              : 'services.action_resume'.tr(),
          icon: service.isActive
              ? Icons.pause_circle_outline
              : Icons.play_circle_outline,
          color: service.isActive ? colors.warning : colors.primary,
          onTap: () => _onStatusTogglePressed(context),
        ),
        const AppDivider(),
        _ServiceActionRow(
          label: 'services.action_delete'.tr(),
          svgAsset: AppSvgs.trash,
          color: colors.error,
          onTap: () => _onDeletePressed(context),
        ),
      ],
    );
  }

  Future<void> _onEditPressed(BuildContext context) async {
    Navigator.of(context).pop();
    if (!pageContext.mounted) return;

    final confirmed = await showServiceConfirmationSheet(
      context: pageContext,
      title: 'services.edit_confirm_title'.tr(),
      description: 'services.edit_confirm_description'.tr(),
      serviceName: service.name,
      actionLabel: 'services.edit_confirm_action'.tr(),
      cancelLabel: 'services.edit_confirm_cancel'.tr(),
    );
    if (!(confirmed ?? false) || !pageContext.mounted) return;

    final updated = await pageContext.push<ServiceRecordEntity>(
      ServiceRoutes.editFor(service.id),
      extra: service,
    );
    if (updated != null && pageContext.mounted) {
      pageContext.read<ServiceActionBloc>().add(
        ServiceExternallyUpdatedEvent(updated),
      );
    }
  }

  Future<void> _onStatusTogglePressed(BuildContext context) async {
    Navigator.of(context).pop();
    if (!pageContext.mounted) return;

    final isActive = service.isActive;
    final confirmed = await showServiceConfirmationSheet(
      context: pageContext,
      title: isActive
          ? 'services.pause_confirm_title'.tr()
          : 'services.resume_confirm_title'.tr(),
      description: isActive
          ? 'services.pause_confirm_description'.tr()
          : 'services.resume_confirm_description'.tr(),
      serviceName: service.name,
      actionLabel: isActive
          ? 'services.pause_confirm'.tr()
          : 'services.resume_confirm_action'.tr(),
      cancelLabel: isActive
          ? 'services.cancel'.tr()
          : 'services.resume_confirm_cancel'.tr(),
      actionType: isActive ? AppButtonType.warning : AppButtonType.primary,
    );

    if ((confirmed ?? false) && pageContext.mounted) {
      pageContext.read<ServiceActionBloc>().add(
        ServiceStatusToggleRequestedEvent(
          serviceId: service.id,
          isActive: !isActive,
        ),
      );
    }
  }

  Future<void> _onDeletePressed(BuildContext context) async {
    Navigator.of(context).pop();
    if (!pageContext.mounted) return;

    final confirmed = await showServiceConfirmationSheet(
      context: pageContext,
      title: 'services.delete_confirm_title'.tr(),
      description: 'services.delete_confirm_description'.tr(),
      serviceName: service.name,
      actionLabel: 'services.delete_confirm'.tr(),
      cancelLabel: 'services.cancel'.tr(),
      destructive: true,
    );

    if ((confirmed ?? false) && pageContext.mounted) {
      pageContext.read<ServiceActionBloc>().add(
        ServiceDeleteRequestedEvent(service.id),
      );
    }
  }
}

/// Tappable row with a colored icon + label — Figma `5261:44521`/`5261:44579`
/// action rows (Edit/Pause-or-Resume/Delete).
class _ServiceActionRow extends StatelessWidget {
  const _ServiceActionRow({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.svgAsset,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final String? svgAsset;

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
              if (svgAsset != null)
                AppSvgPicture.asset(
                  svgAsset!,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                )
              else
                Icon(icon, size: 24, color: color),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: typography.regularNormal.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
