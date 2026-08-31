import 'package:auth/src/domain/enums/client_auth_method.dart';
import 'package:equatable/equatable.dart';

/// Params for `EmailDto` calls — shared by signup, login, and resend-otp
/// (all three are just `{email}` on the wire).
class RequestEmailOtpParams extends Equatable {
  const RequestEmailOtpParams({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Params for `EmailOtpDto` calls — shared by signup/verify and login/verify.
class VerifyEmailOtpParams extends Equatable {
  const VerifyEmailOtpParams({required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  List<Object?> get props => [email, otp];
}

/// Params for `POST auth/client/request-otp` and `GET auth/client/resend-info`
/// — the unified client OTP dispatch/cooldown, keyed on `{method, value}`.
class ClientOtpParams extends Equatable {
  const ClientOtpParams({required this.method, required this.value});

  final ClientAuthMethod method;
  final String value;

  @override
  List<Object?> get props => [method, value];
}

/// Params for `POST auth/client/verify` — the same `{method, value}` plus the
/// 6-digit code.
class VerifyClientOtpParams extends Equatable {
  const VerifyClientOtpParams({
    required this.method,
    required this.value,
    required this.otp,
  });

  final ClientAuthMethod method;
  final String value;
  final String otp;

  @override
  List<Object?> get props => [method, value, otp];
}

/// Params for `PATCH clients/me` — at least one field must be non-null (the
/// backend rejects an empty body).
class UpdateClientProfileParams extends Equatable {
  const UpdateClientProfileParams({this.name, this.preferredLanguage});

  final String? name;
  final String? preferredLanguage;

  @override
  List<Object?> get props => [name, preferredLanguage];
}
