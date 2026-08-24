import 'package:easy_localization/easy_localization.dart';
import 'package:workers/src/domain/entities/worker_type.dart';

/// Localized display label for [WorkerType] — the single source of truth
/// consumed by every place that shows a worker's type (list row caption,
/// the add-branch worker card's fallback, and the details page's contact
/// card), so a Team list row and the details page can never drift apart.
///
/// [WorkerType] is a stable, closed, 2-value backend enum (`worker` /
/// `manager`) — unlike `WorkerEntity.jobTitle`, which is free text the
/// inviting user typed in and is never localized here or anywhere else (see
/// `CreateInvitationDto.jobTitle` / `UpdateWorkerDto.jobTitle` in the live
/// API contract: nullable, user-supplied, no `x-lang` behavior documented).
extension WorkerTypeLocalizedLabel on WorkerType {
  String localizedLabel() => switch (this) {
    WorkerType.worker => 'workers.add_worker.type_worker'.tr(),
    WorkerType.manager => 'workers.add_worker.type_manager'.tr(),
  };
}
