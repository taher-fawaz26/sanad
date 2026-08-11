import 'package:workers/src/domain/entities/worker_status.dart';

/// Request body for `PATCH /workers/{id}/status` (`UpdateWorkerStatusDto`).
///
/// Backend contract: `status` is required and must be `active` | `inactive`.
class UpdateWorkerStatusDto {
  const UpdateWorkerStatusDto(this.status);

  factory UpdateWorkerStatusDto.fromStatus(WorkerStatus status) =>
      UpdateWorkerStatusDto(status.toApiValue());

  /// `active` | `inactive`.
  final String status;

  Map<String, dynamic> toJson() => {'status': status};
}
