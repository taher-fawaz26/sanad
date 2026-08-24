import 'package:account_settings/src/domain/entities/deletion_resend_info.dart';

/// `AccountDeletionResendInfoDto`.
class AccountDeletionResendInfoDto {
  const AccountDeletionResendInfoDto({
    required this.canResend,
    required this.remainingSeconds,
    required this.attemptsLeft,
  });

  factory AccountDeletionResendInfoDto.fromJson(Map<String, dynamic> json) =>
      AccountDeletionResendInfoDto(
        canResend: json['canResend'] as bool? ?? false,
        remainingSeconds: (json['remainingSeconds'] as num?)?.toInt() ?? 0,
        attemptsLeft: (json['attemptsLeft'] as num?)?.toInt() ?? 0,
      );

  final bool canResend;
  final int remainingSeconds;
  final int attemptsLeft;

  DeletionResendInfo toEntity() => DeletionResendInfo(
    canResend: canResend,
    remainingSeconds: remainingSeconds,
    attemptsLeft: attemptsLeft,
  );
}
