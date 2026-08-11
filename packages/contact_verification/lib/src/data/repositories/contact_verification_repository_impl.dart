import 'package:contact_verification/src/data/datasources/contact_verification_remote_datasource.dart';
import 'package:contact_verification/src/domain/entities/verification_dispatch.dart';
import 'package:contact_verification/src/domain/entities/verification_resend_info.dart';
import 'package:contact_verification/src/domain/entities/verification_result.dart';
import 'package:contact_verification/src/domain/repositories/contact_verification_repository.dart';
import 'package:contact_verification/src/domain/usecases/contact_verification_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class ContactVerificationRepositoryImpl
    implements ContactVerificationRepository {
  const ContactVerificationRepositoryImpl(this._remote);

  final ContactVerificationRemoteDataSource _remote;

  @override
  TaskEither<Failure, VerificationDispatch> requestCode(
    RequestVerificationParams params,
  ) => _remote
      .requestCode(purpose: params.purpose, target: params.target)
      .map((response) => response.toEntity());

  @override
  TaskEither<Failure, VerificationDispatch> resendCode(
    ResendVerificationParams params,
  ) => _remote
      .resendCode(purpose: params.purpose)
      .map((response) => response.toEntity());

  @override
  TaskEither<Failure, VerificationResendInfo> getResendInfo(
    ResendInfoParams params,
  ) => _remote
      .getResendInfo(purpose: params.purpose)
      .map((response) => response.toEntity());

  @override
  TaskEither<Failure, VerificationResult> verifyCode(
    VerifyContactParams params,
  ) => _remote
      .verifyCode(purpose: params.purpose, code: params.code)
      .map((response) => response.toEntity());
}
