import 'package:contact_verification/src/data/datasources/contact_verification_remote_datasource.dart';
import 'package:contact_verification/src/data/models/verification_dispatch_response.dart';
import 'package:contact_verification/src/data/models/verification_resend_info_response.dart';
import 'package:contact_verification/src/data/repositories/contact_verification_repository_impl.dart';
import 'package:contact_verification/src/domain/entities/verification_purpose.dart';
import 'package:contact_verification/src/domain/usecases/contact_verification_params.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements ContactVerificationRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late ContactVerificationRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    repository = ContactVerificationRepositoryImpl(remote);
  });

  test('requestCode maps the response DTO to a domain entity', () async {
    when(
      () => remote.requestCode(
        purpose: VerificationPurpose.changeBusinessEmail,
        target: 'new@biz.com',
      ),
    ).thenAnswer(
      (_) => TaskEither.right(
        const VerificationDispatchResponse(message: 'sent', code: '055555'),
      ),
    );

    final result = await repository
        .requestCode(
          const RequestVerificationParams(
            purpose: VerificationPurpose.changeBusinessEmail,
            target: 'new@biz.com',
          ),
        )
        .run();

    expect(result.isRight(), isTrue);
    result.match((_) => fail('expected success'), (dispatch) {
      expect(dispatch.message, 'sent');
      expect(dispatch.devCode, '055555');
    });
  });

  test('verifyCode propagates a failure', () async {
    when(
      () => remote.verifyCode(
        purpose: VerificationPurpose.changeOwnerPhone,
        code: '000000',
      ),
    ).thenAnswer(
      (_) => TaskEither.left(const ConflictFailure(message: 'in use')),
    );

    final result = await repository
        .verifyCode(
          const VerifyContactParams(
            purpose: VerificationPurpose.changeOwnerPhone,
            code: '000000',
          ),
        )
        .run();

    expect(result.isLeft(), isTrue);
    result.match(
      (failure) => expect(failure, isA<ConflictFailure>()),
      (_) => fail('expected failure'),
    );
  });

  test('getResendInfo maps the response DTO to a domain entity', () async {
    when(
      () => remote.getResendInfo(purpose: VerificationPurpose.changeOwnerEmail),
    ).thenAnswer(
      (_) => TaskEither.right(
        const VerificationResendInfoResponse(
          canResend: false,
          remainingSeconds: 30,
          attemptsLeft: 2,
        ),
      ),
    );

    final result = await repository
        .getResendInfo(
          const ResendInfoParams(purpose: VerificationPurpose.changeOwnerEmail),
        )
        .run();

    result.match((_) => fail('expected success'), (info) {
      expect(info.canResend, isFalse);
      expect(info.remainingSeconds, 30);
      expect(info.attemptsLeft, 2);
    });
  });

  test('resendCode delegates to the remote data source', () async {
    when(
      () => remote.resendCode(purpose: VerificationPurpose.changeBusinessPhone),
    ).thenAnswer(
      (_) => TaskEither.right(
        const VerificationDispatchResponse(message: 'resent'),
      ),
    );

    await repository
        .resendCode(
          const ResendVerificationParams(
            purpose: VerificationPurpose.changeBusinessPhone,
          ),
        )
        .run();

    verify(
      () => remote.resendCode(purpose: VerificationPurpose.changeBusinessPhone),
    ).called(1);
  });
}
