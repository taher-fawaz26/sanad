import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/widgets/service_confirmation_sheet.dart';
import 'package:services/src/routes/service_routes.dart';

/// Confirms then navigates to edit [service], re-broadcasting the result via
/// [ServiceExternallyUpdatedEvent].
///
/// Shared by any invocation surface (the details-page actions sheet, and
/// `AppSwipeActions` on the My Services list) so they run the exact same
/// confirmation + business logic.
Future<void> confirmAndEditService({
  required BuildContext context,
  required ProviderServiceEntity service,
}) async {
  final confirmed = await showServiceConfirmationSheet(
    context: context,
    title: 'services.edit_confirm_title'.tr(),
    description: 'services.edit_confirm_description'.tr(),
    serviceName: service.serviceName,
    actionLabel: 'common.yes'.tr(),
    cancelLabel: 'common.close'.tr(),
  );
  if (!(confirmed ?? false) || !context.mounted) return;

  final updated = await context.push<ProviderServiceEntity>(
    ServiceRoutes.editFor(service.id),
    extra: service,
  );
  if (updated != null && context.mounted) {
    context.read<ServiceActionBloc>().add(
      ServiceExternallyUpdatedEvent(updated),
    );
  }
}

/// Confirms then pauses/resumes [service] via [ServiceActionBloc].
Future<void> confirmAndToggleServiceStatus({
  required BuildContext context,
  required ProviderServiceEntity service,
}) async {
  final isActive = service.status == ProviderServiceStatus.active;
  final confirmed = await showServiceConfirmationSheet(
    context: context,
    title: isActive
        ? 'services.pause_confirm_title'.tr()
        : 'services.resume_confirm_title'.tr(),
    description: isActive
        ? 'services.pause_confirm_description'.tr()
        : 'services.resume_confirm_description'.tr(),
    serviceName: service.serviceName,
    actionLabel: isActive
        ? 'services.pause_confirm'.tr()
        : 'common.yes'.tr(),
    cancelLabel: isActive
        ? 'common.cancel'.tr()
        : 'common.close'.tr(),
    actionType: isActive ? AppButtonType.warning : AppButtonType.primary,
  );

  if ((confirmed ?? false) && context.mounted) {
    context.read<ServiceActionBloc>().add(
      ServiceStatusToggleRequestedEvent(
        serviceId: service.id,
        status: isActive
            ? ProviderServiceStatus.inactive
            : ProviderServiceStatus.active,
      ),
    );
  }
}

/// Confirms then deletes [service] via [ServiceActionBloc].
Future<void> confirmAndDeleteService({
  required BuildContext context,
  required ProviderServiceEntity service,
}) async {
  final confirmed = await showServiceConfirmationSheet(
    context: context,
    title: 'services.delete_confirm_title'.tr(),
    description: 'services.delete_confirm_description'.tr(),
    serviceName: service.serviceName,
    actionLabel: 'services.delete_confirm'.tr(),
    cancelLabel: 'common.cancel'.tr(),
    destructive: true,
  );

  if ((confirmed ?? false) && context.mounted) {
    context.read<ServiceActionBloc>().add(
      ServiceDeleteRequestedEvent(service.id),
    );
  }
}
