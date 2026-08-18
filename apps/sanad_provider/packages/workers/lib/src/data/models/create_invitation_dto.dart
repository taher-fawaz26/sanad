import 'package:workers/src/domain/usecases/invite_worker_usecase.dart';

/// Request body for `POST /workers/invitations` (`CreateInvitationDto`).
///
/// Backend contract: `name`, `email`, `phone`, `type`, `roleIds` are
/// required; `jobTitle` is optional and omitted from the payload when
/// absent. `roleIds` must carry at least one id — an invitation that grants
/// nothing produces a member who can do nothing — and the backend adds the
/// type's baseline system role on top automatically if it's missing.
class CreateInvitationDto {
  const CreateInvitationDto({
    required this.name,
    required this.email,
    required this.phone,
    required this.type,
    required this.roleIds,
    this.jobTitle,
  });

  factory CreateInvitationDto.fromParams(InviteWorkerParams params) =>
      CreateInvitationDto(
        name: params.fullName,
        email: params.email,
        phone: params.phone,
        type: params.type.toApiString(),
        roleIds: params.roleIds,
        jobTitle: params.jobTitle.isEmpty ? null : params.jobTitle,
      );

  final String name;
  final String email;
  final String phone;

  /// `worker` | `manager`.
  final String type;
  final List<String> roleIds;
  final String? jobTitle;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    if (jobTitle != null) 'jobTitle': jobTitle,
    'type': type,
    'roleIds': roleIds,
  };
}
