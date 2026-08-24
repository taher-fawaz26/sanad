import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:localization/localization.dart';
import 'package:workers/src/presentation/bloc/worker_action/worker_action_cubit.dart';

/// Copy for [WorkerActionCubit] effects — shared by every surface that can
/// trigger a suspend/unsuspend/delete (the Team list's swipe actions and the
/// Worker Details page's "more actions" sheet), so both show byte-identical
/// progress/success/failure text for the same action.
String workerActionProgressTitle(WorkerActionType type) => switch (type) {
  WorkerActionType.suspend => 'workers.worker_suspend_in_progress'.tr(),
  WorkerActionType.unsuspend => 'workers.worker_unsuspend_in_progress'.tr(),
  WorkerActionType.delete => 'workers.worker_delete_in_progress'.tr(),
};

String workerActionSuccessMessage(WorkerActionType type) => switch (type) {
  WorkerActionType.suspend => 'workers.worker_suspended'.tr(),
  WorkerActionType.unsuspend => 'workers.worker_unsuspended'.tr(),
  WorkerActionType.delete => 'workers.worker_deleted'.tr(),
};

String workerActionFailureMessage(WorkerActionType type, Failure failure) {
  if (failure.message.trim().isNotEmpty) return failure.localizedMessage();
  return switch (type) {
    WorkerActionType.suspend => 'workers.worker_suspend_failed'.tr(),
    WorkerActionType.unsuspend => 'workers.worker_unsuspend_failed'.tr(),
    WorkerActionType.delete => 'workers.worker_delete_failed'.tr(),
  };
}
