import 'package:contact_verification/src/domain/entities/verification_purpose.dart';
import 'package:equatable/equatable.dart';

class RequestVerificationParams extends Equatable {
  const RequestVerificationParams({
    required this.purpose,
    required this.target,
  });

  final VerificationPurpose purpose;

  /// The new email address or UAE mobile number being claimed.
  final String target;

  @override
  List<Object?> get props => [purpose, target];
}

class ResendVerificationParams extends Equatable {
  const ResendVerificationParams({required this.purpose});

  final VerificationPurpose purpose;

  @override
  List<Object?> get props => [purpose];
}

class ResendInfoParams extends Equatable {
  const ResendInfoParams({required this.purpose});

  final VerificationPurpose purpose;

  @override
  List<Object?> get props => [purpose];
}

class VerifyContactParams extends Equatable {
  const VerifyContactParams({required this.purpose, required this.code});

  final VerificationPurpose purpose;

  /// The 6-digit code that was delivered.
  final String code;

  @override
  List<Object?> get props => [purpose, code];
}
