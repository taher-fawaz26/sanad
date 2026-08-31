import 'package:auth/src/domain/enums/client_auth_method.dart';
import 'package:equatable/equatable.dart';

/// Body for `POST auth/client/request-otp` — the unified client OTP dispatch
/// (works identically for first-time and returning clients).
///
/// [value] must match [method]: a standard email for [ClientAuthMethod.email],
/// or a UAE mobile in full international format (e.g. `+971501234567`) for
/// [ClientAuthMethod.phone]. It is stored verbatim and reused, unchanged, by
/// verify — never re-normalized.
class ClientOtpRequest extends Equatable {
  const ClientOtpRequest({required this.method, required this.value});

  final ClientAuthMethod method;
  final String value;

  Map<String, dynamic> toMap() => {'method': method.value, 'value': value};

  @override
  List<Object?> get props => [method, value];
}
