import 'package:contact_verification/src/domain/entities/verification_resend_info.dart';

/// Mirrors `VerificationResendInfoResponseDto`.
class VerificationResendInfoResponse {
  const VerificationResendInfoResponse({
    required this.canResend,
    required this.remainingSeconds,
    required this.attemptsLeft,
  });

  factory VerificationResendInfoResponse.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);
    return VerificationResendInfoResponse(
      canResend: map['canResend'] as bool? ?? false,
      remainingSeconds: (map['remainingSeconds'] as num?)?.toInt() ?? 0,
      attemptsLeft: (map['attemptsLeft'] as num?)?.toInt() ?? 0,
    );
  }

  final bool canResend;
  final int remainingSeconds;
  final int attemptsLeft;

  VerificationResendInfo toEntity() => VerificationResendInfo(
    canResend: canResend,
    remainingSeconds: remainingSeconds,
    attemptsLeft: attemptsLeft,
  );

  static Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    return raw;
  }
}
