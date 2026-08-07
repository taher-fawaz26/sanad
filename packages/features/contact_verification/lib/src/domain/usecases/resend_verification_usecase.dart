import 'package:contact_verification/src/domain/entities/verification_dispatch.dart';
import 'package:contact_verification/src/domain/repositories/contact_verification_repository.dart';
import 'package:contact_verification/src/domain/usecases/contact_verification_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class ResendVerificationUseCase
    implements UseCase<VerificationDispatch, ResendVerificationParams> {
  const ResendVerificationUseCase(this._repository);

  final ContactVerificationRepository _repository;

  @override
  TaskEither<Failure, VerificationDispatch> call(
    ResendVerificationParams params,
  ) => _repository.resendCode(params);
}
