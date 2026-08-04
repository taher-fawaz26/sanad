import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/src/domain/contracts/otp_verifier.dart';
import 'package:otp/src/domain/entities/otp_delivery.dart';

/// Adapts two closures into an [OtpVerifier] — the quickest way to wire a
/// mock, a stub, or a call site that doesn't warrant its own verifier class.
class CallbackOtpVerifier<T> implements OtpVerifier<T> {
  const CallbackOtpVerifier({
    required TaskEither<Failure, OtpDelivery> Function() onRequestCode,
    required TaskEither<Failure, T> Function(String code) onVerifyCode,
  }) : _onRequestCode = onRequestCode,
       _onVerifyCode = onVerifyCode;

  final TaskEither<Failure, OtpDelivery> Function() _onRequestCode;
  final TaskEither<Failure, T> Function(String code) _onVerifyCode;

  @override
  TaskEither<Failure, OtpDelivery> requestCode() => _onRequestCode();

  @override
  TaskEither<Failure, T> verifyCode(String code) => _onVerifyCode(code);
}
