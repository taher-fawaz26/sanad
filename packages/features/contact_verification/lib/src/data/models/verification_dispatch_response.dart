import 'package:contact_verification/src/domain/entities/verification_dispatch.dart';

/// Mirrors `VerificationDispatchResponseDto`.
class VerificationDispatchResponse {
  const VerificationDispatchResponse({required this.message, this.code});

  factory VerificationDispatchResponse.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);
    return VerificationDispatchResponse(
      message: map['message'] as String? ?? '',
      code: map['code'] as String?,
    );
  }

  final String message;

  /// Returned only in development (`DEFAULT_OTP` short-circuit).
  final String? code;

  VerificationDispatch toEntity() =>
      VerificationDispatch(message: message, devCode: code);

  static Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    return raw;
  }
}
