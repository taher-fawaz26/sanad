import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/src/domain/entities/otp_delivery.dart';

/// The seam between the generic OTP UI and a caller's own backend.
///
/// Implement this per use case (email login, change-phone, MFA, ...) and pass
/// it into `OtpFlowConfig`. This package never imports a network client —
/// every send/verify call is the caller's responsibility.
abstract interface class OtpVerifier<T> {
  /// Sends (or resends) the code. Called once on flow start and again on
  /// every resend tap.
  TaskEither<Failure, OtpDelivery> requestCode();

  /// Verifies [code]. Resolves to whatever the caller wants returned to
  /// `OtpFlow.start`'s caller on success (e.g. a session entity).
  TaskEither<Failure, T> verifyCode(String code);
}
