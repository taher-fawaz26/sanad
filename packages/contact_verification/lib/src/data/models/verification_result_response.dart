import 'package:contact_verification/src/domain/entities/verification_purpose.dart';
import 'package:contact_verification/src/domain/entities/verification_result.dart';

/// Mirrors `VerificationResultResponseDto`.
class VerificationResultResponse {
  const VerificationResultResponse({
    required this.purpose,
    required this.target,
    required this.message,
  });

  /// [requestedPurpose] is what the client asked to verify, used as the
  /// fallback when the response echoes a purpose we cannot parse.
  ///
  /// The strict parse used to be an unchecked cast, so a missing or unknown
  /// `purpose` threw on the *success* path — losing a verification the
  /// backend had already committed. The value is echoed back to us, so
  /// falling back to what we sent is both safe and accurate.
  factory VerificationResultResponse.fromJson(
    Map<String, dynamic> json, {
    required VerificationPurpose requestedPurpose,
  }) {
    final map = _unwrap(json);
    return VerificationResultResponse(
      purpose:
          VerificationPurpose.tryFromApi(map['purpose']) ?? requestedPurpose,
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
