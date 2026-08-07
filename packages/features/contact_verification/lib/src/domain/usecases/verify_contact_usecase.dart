import 'package:contact_verification/src/domain/entities/verification_result.dart';
import 'package:contact_verification/src/domain/repositories/contact_verification_repository.dart';
import 'package:contact_verification/src/domain/usecases/contact_verification_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class VerifyContactUseCase
    implements UseCase<VerificationResult, VerifyContactParams> {
  const VerifyContactUseCase(this._repository);

  final ContactVerificationRepository _repository;

  @override
  TaskEither<Failure, VerificationResult> call(VerifyContactParams params) =>
      _repository.verifyCode(params);
}
