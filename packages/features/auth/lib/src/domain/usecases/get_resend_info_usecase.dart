import 'package:auth/src/domain/entities/resend_info_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// `GET /auth/resend-info?email=` — server-driven resend cooldown.
class GetResendInfoUseCase
    implements UseCase<ResendInfo, RequestEmailOtpParams> {
  const GetResendInfoUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, ResendInfo> call(RequestEmailOtpParams params) =>
      _repository.getResendInfo(params);
}
