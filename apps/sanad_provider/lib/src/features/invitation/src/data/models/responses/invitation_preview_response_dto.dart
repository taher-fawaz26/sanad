import 'package:sanad_provider/src/features/invitation/src/domain/entities/invitation_preview_entity.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/entities/invitation_status.dart';
import 'package:workers/workers.dart' show WorkerType;

/// Data model for [InvitationPreview] — inherits fields, adds JSON I/O.
class InvitationPreviewModel extends InvitationPreview {
  const InvitationPreviewModel({
    required super.valid,
    super.status,
    super.email,
    super.workerType,
    super.providerName,
  });

  factory InvitationPreviewModel.fromJson(Map<String, dynamic> json) {
    final rawValid = json['valid'];
    if (rawValid is! bool) {
      throw const FormatException(
        'VerifyInvitationTokenResponseDto.valid is required and must be a '
        'boolean.',
      );
    }

    final rawStatus = json['status'];
    final rawWorkerType = json['workerType'];

    return InvitationPreviewModel(
      valid: rawValid,
      status: rawStatus is String
          ? InvitationStatus.fromString(rawStatus)
          : null,
      email: json['email'] as String?,
      workerType: rawWorkerType is String
          ? WorkerType.fromApiString(rawWorkerType)
          : null,
      providerName: json['providerName'] as String?,
    );
  }
}
