import 'package:contact_verification/src/domain/entities/verification_dispatch.dart';
import 'package:contact_verification/src/domain/repositories/contact_verification_repository.dart';
import 'package:contact_verification/src/domain/usecases/contact_verification_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class RequestVerificationUseCase
    implements UseCase<VerificationDispatch, RequestVerificationParams> {
  const RequestVerificationUseCase(this._repository);

  final ContactVerificationRepository _repository;

  @override
  TaskEither<Failure, VerificationDispatch> call(
    RequestVerificationParams params,
  ) => _repository.requestCode(params);
}
