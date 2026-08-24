import 'package:account_settings/src/domain/entities/account_deletion_request.dart';
import 'package:account_settings/src/domain/enums/account_deletion_status.dart';

/// `AccountDeletionResponseDto` — returned by initiate / verify / resend-otp
/// / status.
class AccountDeletionResponseDto {
  const AccountDeletionResponseDto({
    required this.id,
    required this.status,
    required this.initiator,
    required this.cascadeSummary,
    required this.verificationRequired,
    required this.scheduledExecutionDate,
    required this.gracePeriodDays,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountDeletionResponseDto.fromJson(Map<String, dynamic> json) =>
      AccountDeletionResponseDto(
        id: json['id'] as String? ?? '',
        status: json['status'] as String? ?? '',
        initiator: json['initiator'] as String? ?? '',
        cascadeSummary:
            (json['cascadeSummary'] as Map<String, dynamic>?) ?? const {},
        verificationRequired: json['verificationRequired'] as bool? ?? false,
        scheduledExecutionDate: json['scheduledExecutionDate'] as String?,
        gracePeriodDays: (json['gracePeriodDays'] as num?)?.toInt() ?? 0,
        message: json['message'] as String? ?? '',
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );

  final String id;
  final String status;
  final String initiator;
  final Map<String, dynamic> cascadeSummary;
  final bool verificationRequired;
  final String? scheduledExecutionDate;
  final int gracePeriodDays;
  final String message;
  final String? createdAt;
  final String? updatedAt;

  AccountDeletionRequest toEntity() => AccountDeletionRequest(
    id: id,
    status: AccountDeletionStatus.fromApi(status),
    initiator: DeletionInitiator.fromApi(initiator),
    verificationRequired: verificationRequired,
    scheduledExecutionDate: scheduledExecutionDate != null
        ? DateTime.tryParse(scheduledExecutionDate!)
        : null,
    gracePeriodDays: gracePeriodDays,
    message: message,
    createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
    updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
    cascadeSummary: cascadeSummary,
  );
}
