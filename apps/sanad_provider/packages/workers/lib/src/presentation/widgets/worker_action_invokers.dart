import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:workers/src/presentation/bloc/worker_action/worker_action_cubit.dart';

const ({AppButtonVariant variant, AppButtonIntent intent}) _suspendButton = (
  variant: AppButtonVariant.primary,
  intent: AppButtonIntent.warning,
);
const ({AppButtonVariant variant, AppButtonIntent intent}) _unsuspendButton = (
  variant: AppButtonVariant.primary,
  intent: AppButtonIntent.standard,
);
const ({AppButtonVariant variant, AppButtonIntent intent}) _deleteButton = (
  variant: AppButtonVariant.primary,
  intent: AppButtonIntent.destructive,
);

/// Confirms then suspends/unsuspends [worker] via [WorkerActionCubit].
///
/// Shared by the worker actions bottom sheet and `AppSwipeActions` so both
/// invocation surfaces run the exact same confirmation + business logic.
Future<void> confirmAndChangeWorkerStatus({
  required BuildContext context,
  required WorkerEntity worker,
  required bool isSuspending,
}) async {
  final btnConfig = isSuspending ? _suspendButton : _unsuspendButton;
  final confirmed = await showConfirmationSheet(
    context: context,
    title: isSuspending
        ? 'workers.suspend_title'.tr()
        : 'workers.unsuspend_title'.tr(),
    description: isSuspending
        ? 'workers.suspend_description'.tr(namedArgs: {'name': worker.fullName})
        : 'workers.unsuspend_description'.tr(
            namedArgs: {'name': worker.fullName},
          ),
    actionLabel: isSuspending
        ? 'workers.suspend_action'.tr()
        : 'workers.unsuspend_action'.tr(),
    actionVariant: btnConfig.variant,
    actionIntent: btnConfig.intent,
    cancelLabel: 'common.cancel'.tr(),
  );

  if ((confirmed ?? false) && context.mounted) {
    await context.read<WorkerActionCubit>().changeStatus(
      workerId: worker.id,
      status: isSuspending ? WorkerStatus.inactive : WorkerStatus.active,
    );
  }
}

/// Confirms then deletes [worker] via [WorkerActionCubit].
Future<void> confirmAndDeleteWorker({
  required BuildContext context,
  required WorkerEntity worker,
}) async {
  final confirmed = await showConfirmationSheet(
    context: context,
    title: 'workers.delete_title'.tr(),
    description: 'workers.delete_description'.tr(
      namedArgs: {'name': worker.fullName},
    ),
    actionLabel: 'common.delete'.tr(),
    actionVariant: _deleteButton.variant,
    actionIntent: _deleteButton.intent,
    cancelLabel: 'common.cancel'.tr(),
  );

  if ((confirmed ?? false) && context.mounted) {
    await context.read<WorkerActionCubit>().delete(worker.id);
  }
}
