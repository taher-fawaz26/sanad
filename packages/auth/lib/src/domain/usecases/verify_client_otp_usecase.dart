import 'package:auth/src/domain/entities/client_verify_result_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Completes client sign-in — `POST auth/client/verify`. Resolves to a
/// [ClientVerifyResult] the caller branches on (`status` + `user.name`); the
/// account is created here if the identifier is new.
class VerifyClientOtpUseCase
    implements UseCase<ClientVerifyResult, VerifyClientOtpParams> {
  const VerifyClientOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, ClientVerifyResult> call(VerifyClientOtpParams params) =>
      _repository.verifyClientOtp(params);
}
