import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:invitation/src/data/datasources/invitation_remote_datasource.dart';
import 'package:invitation/src/data/repositories/invitation_repository_impl.dart';
import 'package:invitation/src/domain/entities/invitation_preview_entity.dart';
import 'package:invitation/src/domain/usecases/usecase_params.dart';
import 'package:mocktail/mocktail.dart';

class _MockInvitationRemoteDataSource extends Mock
    implements InvitationRemoteDataSource {}

class _FakeAuthSession extends Fake implements AuthSessionEntity {}

void main() {
  late _MockInvitationRemoteDataSource remote;
  late InvitationRepositoryImpl repository;

  const token = '11111111-1111-1111-1111-111111111111';

  setUp(() {
    remote = _MockInvitationRemoteDataSource();
    repository = InvitationRepositoryImpl(remote);
  });

  group('verifyToken', () {
    test('delegates to the remote data source with the token', () async {
      const preview = InvitationPreview(valid: true, email: 'a@b.com');
      when(() => remote.verifyToken(token)).thenReturn(
        TaskEither.right(preview),
      );

      final result = await repository
          .verifyToken(const InvitationTokenParams(token: token))
          .run();

      expect(result, const Right<Failure, InvitationPreview>(preview));
      verify(() => remote.verifyToken(token)).called(1);
    });

    test('propagates a Failure', () async {
      const failure = ValidationFailure(message: 'bad token');
      when(() => remote.verifyToken(token)).thenReturn(
        TaskEither.left(failure),
      );

      final result = await repository
          .verifyToken(const InvitationTokenParams(token: token))
          .run();

      expect(result, const Left<Failure, InvitationPreview>(failure));
    });
  });

  test('requestOtp delegates to the remote data source', () async {
    when(() => remote.requestOtp(token)).thenReturn(TaskEither.right(null));

    final result = await repository
        .requestOtp(const InvitationTokenParams(token: token))
        .run();

    expect(result.isRight(), isTrue);
    verify(() => remote.requestOtp(token)).called(1);
  });

  test('resendOtp delegates to the remote data source', () async {
    when(() => remote.resendOtp(token)).thenReturn(TaskEither.right(null));

    final result = await repository
        .resendOtp(const InvitationTokenParams(token: token))
        .run();

    expect(result.isRight(), isTrue);
    verify(() => remote.resendOtp(token)).called(1);
  });

  test('getResendInfo delegates to the remote data source', () async {
    const info = ResendInfo(
      canResend: false,
      remainingSeconds: 45,
      attemptsLeft: 2,
    );
    when(() => remote.getResendInfo(token)).thenReturn(
      TaskEither.right(info),
    );

    final result = await repository
        .getResendInfo(const InvitationTokenParams(token: token))
        .run();

    expect(result, const Right<Failure, ResendInfo>(info));
  });

  test('accept delegates to the remote data source with token + otp', () async {
    final session = _FakeAuthSession();
    when(
      () => remote.accept(token: token, otp: '123456'),
    ).thenReturn(TaskEither.right(session));

    final result = await repository
        .accept(const AcceptInvitationParams(token: token, otp: '123456'))
        .run();

    expect(result, Right<Failure, AuthSessionEntity>(session));
    verify(() => remote.accept(token: token, otp: '123456')).called(1);
  });
}
