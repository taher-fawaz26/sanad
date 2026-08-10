import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:invitation/src/data/datasources/invitation_remote_datasource.dart';
import 'package:invitation/src/domain/entities/invitation_preview_entity.dart';
import 'package:invitation/src/domain/repositories/invitation_repository.dart';
import 'package:invitation/src/domain/usecases/usecase_params.dart';

class InvitationRepositoryImpl implements InvitationRepository {
  const InvitationRepositoryImpl(this._remoteDataSource);

  final InvitationRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, InvitationPreview> verifyToken(
    InvitationTokenParams params,
  ) => _remoteDataSource.verifyToken(params.token);

  @override
  TaskEither<Failure, void> requestOtp(InvitationTokenParams params) =>
      _remoteDataSource.requestOtp(params.token);

  @override
  TaskEither<Failure, void> resendOtp(InvitationTokenParams params) =>
      _remoteDataSource.resendOtp(params.token);

  @override
  TaskEither<Failure, ResendInfo> getResendInfo(
    InvitationTokenParams params,
  ) => _remoteDataSource.getResendInfo(params.token);

  @override
  TaskEither<Failure, AuthSessionEntity> accept(
    AcceptInvitationParams params,
  ) => _remoteDataSource.accept(token: params.token, otp: params.otp);
}
