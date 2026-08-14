import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/presentation/bloc/worker_action/worker_action_cubit.dart';
import 'package:workers/src/presentation/widgets/action_confirmation_sheet.dart';

const ({AppButtonType type, bool destructive}) _suspendButton = (
  type: AppButtonType.warning,
  destructive: false,
);
const ({AppButtonType type, bool destructive}) _unsuspendButton = (
  type: AppButtonType.primary,
  destructive: false,
);
const ({AppButtonType type, bool destructive}) _deleteButton = (
  type: AppButtonType.primary,
  destructive: true,
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
  final confirmed = await showWorkerConfirmationSheet(
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
    actionType: btnConfig.type,
    destructive: btnConfig.destructive,
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
  final confirmed = await showWorkerConfirmationSheet(
    context: context,
    title: 'workers.delete_title'.tr(),
    description: 'workers.delete_description'.tr(
      namedArgs: {'name': worker.fullName},
    ),
    actionLabel: 'common.delete'.tr(),
    actionType: _deleteButton.type,
    destructive: _deleteButton.destructive,
    cancelLabel: 'common.cancel'.tr(),
  );

  if ((confirmed ?? false) && context.mounted) {
    await context.read<WorkerActionCubit>().delete(worker.id);
  }
}
