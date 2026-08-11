import 'package:workers/src/domain/usecases/invite_worker_usecase.dart';

/// Request body for `POST /workers/invitations` (`CreateInvitationDto`).
///
/// Backend contract: `name`, `email`, `phone`, `type` are required;
/// `jobTitle` is optional and omitted from the payload when absent.
class CreateInvitationDto {
  const CreateInvitationDto({
    required this.name,
    required this.email,
    required this.phone,
    required this.type,
    this.jobTitle,
  });

  factory CreateInvitationDto.fromParams(InviteWorkerParams params) =>
      CreateInvitationDto(
        name: params.fullName,
        email: params.email,
        phone: params.phone,
        type: params.type.toApiString(),
        jobTitle: params.jobTitle.isEmpty ? null : params.jobTitle,
      );

  final String name;
  final String email;
  final String phone;

  /// `worker` | `manager`.
  final String type;
  final String? jobTitle;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    if (jobTitle != null) 'jobTitle': jobTitle,
    'type': type,
  };
}
