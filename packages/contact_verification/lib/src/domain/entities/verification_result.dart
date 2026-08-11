import 'package:contact_verification/src/domain/entities/verification_purpose.dart';
import 'package:equatable/equatable.dart';

/// Result of `POST /contact-verification/verify` — the change has already
/// been applied server-side by the time this is returned.
class VerificationResult extends Equatable {
  const VerificationResult({
    required this.purpose,
    required this.target,
    required this.message,
  });

  final VerificationPurpose purpose;

  /// The normalized value that was applied (email or E.164-ish phone).
  final String target;
  final String message;

  @override
  List<Object?> get props => [purpose, target, message];
}
