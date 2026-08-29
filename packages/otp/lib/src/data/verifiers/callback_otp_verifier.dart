import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/src/domain/contracts/otp_verifier.dart';
import 'package:otp/src/domain/entities/otp_cooldown.dart';
import 'package:otp/src/domain/entities/otp_delivery.dart';

/// Adapts closures into an [OtpVerifier] — the quickest way to wire a mock, a
/// stub, or a call site that does not warrant its own verifier class.
///
/// Only `onRequestCode` and `onVerifyCode` are required; resend falls back
/// to request and the cooldown probe reports "unsupported", exactly as
/// [OtpVerifierBase] does.
class CallbackOtpVerifier<T> extends OtpVerifierBase<T> {
  const CallbackOtpVerifier({
    required TaskEither<Failure, OtpDelivery> Function() onRequestCode,
    required TaskEither<Failure, T> Function(String code) onVerifyCode,
    TaskEither<Failure, OtpDelivery> Function()? onResendCode,
    TaskEither<Failure, OtpCooldown> Function()? onCooldown,
  }) : _onRequestCode = onRequestCode,
       _onVerifyCode = onVerifyCode,
       _onResendCode = onResendCode,
       _onCooldown = onCooldown;

  final TaskEither<Failure, OtpDelivery> Function() _onRequestCode;
  final TaskEither<Failure, T> Function(String code) _onVerifyCode;
  final TaskEither<Failure, OtpDelivery> Function()? _onResendCode;
  final TaskEither<Failure, OtpCooldown> Function()? _onCooldown;

  @override
  TaskEither<Failure, OtpDelivery> requestCode() => _onRequestCode();

  @override
  TaskEither<Failure, OtpDelivery> resendCode() =>
      (_onResendCode ?? _onRequestCode)();

  @override
  TaskEither<Failure, OtpCooldown>? cooldown() => _onCooldown?.call();

  @override
  TaskEither<Failure, T> verifyCode(String code) => _onVerifyCode(code);
}
