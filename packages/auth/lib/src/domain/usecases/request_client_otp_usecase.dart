import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Unified client OTP dispatch — `POST auth/client/request-otp`.
///
/// Works identically for first-time and returning clients; the response never
/// reveals registration state. Also used to resend (same endpoint).
class RequestClientOtpUseCase implements UseCase<void, ClientOtpParams> {
  const RequestClientOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, void> call(ClientOtpParams params) =>
      _repository.requestClientOtp(params);
}
