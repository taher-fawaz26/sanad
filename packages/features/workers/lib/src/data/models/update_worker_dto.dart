import 'package:workers/src/domain/usecases/update_worker_usecase.dart';

/// Request body for `PATCH /workers/{id}` (`UpdateWorkerDto`).
///
/// All fields optional; only non-null fields are serialized. Email is not
/// server-editable and is intentionally never sent. Status is changed via the
/// dedicated `/status` endpoint, so it is not populated from the edit form.
class UpdateWorkerDto {
  const UpdateWorkerDto({
    this.name,
    this.phone,
    this.jobTitle,
    this.type,
    this.status,
  });

  factory UpdateWorkerDto.fromParams(UpdateWorkerParams params) =>
      UpdateWorkerDto(
        name: params.fullName,
        phone: params.phone,
        jobTitle: params.jobTitle.isEmpty ? null : params.jobTitle,
        type: params.type.toApiString(),
      );

  final String? name;
  final String? phone;
  final String? jobTitle;

  /// `worker` | `manager`.
  final String? type;

  /// `active` | `inactive`.
  final String? status;

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (phone != null) 'phone': phone,
    if (jobTitle != null) 'jobTitle': jobTitle,
    if (type != null) 'type': type,
    if (status != null) 'status': status,
  };
}
