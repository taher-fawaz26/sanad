import 'package:auth/src/domain/entities/resend_info_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Server-driven client OTP resend cooldown — `GET auth/client/resend-info`.
class GetClientResendInfoUseCase
    implements UseCase<ResendInfo, ClientOtpParams> {
  const GetClientResendInfoUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, ResendInfo> call(ClientOtpParams params) =>
      _repository.getClientResendInfo(params);
}
