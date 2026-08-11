import 'package:contact_verification/src/domain/entities/verification_resend_info.dart';
import 'package:contact_verification/src/domain/repositories/contact_verification_repository.dart';
import 'package:contact_verification/src/domain/usecases/contact_verification_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class GetResendInfoUseCase
    implements UseCase<VerificationResendInfo, ResendInfoParams> {
  const GetResendInfoUseCase(this._repository);

  final ContactVerificationRepository _repository;

  @override
  TaskEither<Failure, VerificationResendInfo> call(ResendInfoParams params) =>
      _repository.getResendInfo(params);
}
