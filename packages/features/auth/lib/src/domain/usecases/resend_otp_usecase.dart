import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// `POST /auth/resend-otp` — single endpoint, not split by intent.
class ResendOtpUseCase implements UseCase<void, RequestEmailOtpParams> {
  const ResendOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, void> call(RequestEmailOtpParams params) =>
      _repository.resendOtp(params);
}
