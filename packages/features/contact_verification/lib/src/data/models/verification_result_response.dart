import 'package:contact_verification/src/domain/entities/verification_purpose.dart';
import 'package:contact_verification/src/domain/entities/verification_result.dart';

/// Mirrors `VerificationResultResponseDto`.
class VerificationResultResponse {
  const VerificationResultResponse({
    required this.purpose,
    required this.target,
    required this.message,
  });

  factory VerificationResultResponse.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);
    return VerificationResultResponse(
      purpose: VerificationPurpose.fromApi(map['purpose'] as String),
      target: map['target'] as String? ?? '',
      message: map['message'] as String? ?? '',
    );
  }

  final VerificationPurpose purpose;
  final String target;
  final String message;

  VerificationResult toEntity() =>
      VerificationResult(purpose: purpose, target: target, message: message);

  static Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    return raw;
  }
}
