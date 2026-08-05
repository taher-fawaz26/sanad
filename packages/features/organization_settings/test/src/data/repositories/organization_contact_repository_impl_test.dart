import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/datasources/organization_contact_remote_datasource.dart';
import 'package:organization_settings/src/data/models/organization_contact_response.dart';
import 'package:organization_settings/src/data/models/requests/contact_email_request.dart';
import 'package:organization_settings/src/data/models/requests/contact_phone_request.dart';
import 'package:organization_settings/src/data/models/requests/verify_email_request.dart';
import 'package:organization_settings/src/data/models/requests/verify_phone_request.dart';
import 'package:organization_settings/src/data/repositories/organization_contact_repository_impl.dart';

class _MockDataSource extends Mock
    implements OrganizationContactRemoteDataSource {}

/// Real pass-through: mocktail can't reliably stub the generic `execute<T>`
/// across differing type arguments, so a Fake mirrors NetworkGuard's
/// connected → run-the-action behaviour.
class _FakeNetworkGuard extends Fake implements NetworkGuard {
  @override
  TaskEither<Failure, T> execute<T>({required TaskEither<Failure, T> action}) =>
      action;
}

void main() {
  late _MockDataSource dataSource;
  late OrganizationContactRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const ContactPhoneRequest(phone: '+971500000000'));
    registerFallbackValue(
      const VerifyPhoneRequest(phone: '+971500000000', otp: '1234'),
    );
    registerFallbackValue(const ContactEmailRequest(email: 'a@b.com'));
    registerFallbackValue(
      const VerifyEmailRequest(email: 'a@b.com', otp: '1234'),
    );
  });

  setUp(() {
    dataSource = _MockDataSource();
    repository = OrganizationContactRepositoryImpl(
      dataSource,
      _FakeNetworkGuard(),
    );
  });

  test('getContact maps the response DTO to a domain entity', () async {
    when(() => dataSource.getContact()).thenAnswer(
      (_) => TaskEither.right(
        const OrganizationContactResponse(
          phone: '500000000',
          email: 'ops@sanad.ae',
          phoneVerified: true,
        ),
      ),
    );

    final result = await repository.getContact().run();

    expect(result.isRight(), isTrue);
    result.match((_) => fail('expected right'), (entity) {
      expect(entity.phone, '500000000');
      expect(entity.email, 'ops@sanad.ae');
      expect(entity.phoneVerified, isTrue);
      expect(entity.emailVerified, isFalse);
    });
  });

  test('requestPhoneOtp delegates through the guard', () async {
    when(
      () => dataSource.requestPhoneOtp(any()),
    ).thenAnswer((_) => TaskEither.right(unit));

    final result = await repository
        .requestPhoneOtp(phone: '+971500000000')
        .run();

    expect(result.isRight(), isTrue);
    verify(
      () => dataSource.requestPhoneOtp(
        const ContactPhoneRequest(phone: '+971500000000'),
      ),
    ).called(1);
  });

  test('verifyPhoneOtp propagates a failure', () async {
    when(() => dataSource.verifyPhoneOtp(any())).thenAnswer(
      (_) => TaskEither.left(const ServerFailure(message: 'invalid otp')),
    );

    final result = await repository
        .verifyPhoneOtp(phone: '+971500000000', otp: '0000')
        .run();

    expect(result.isLeft(), isTrue);
  });

  test('requestEmailOtp delegates through the guard', () async {
    when(
      () => dataSource.requestEmailOtp(any()),
    ).thenAnswer((_) => TaskEither.right(unit));

    final result = await repository
        .requestEmailOtp(email: 'ops@sanad.ae')
        .run();

    expect(result.isRight(), isTrue);
    verify(
      () => dataSource.requestEmailOtp(
        const ContactEmailRequest(email: 'ops@sanad.ae'),
      ),
    ).called(1);
  });

  test('verifyEmailOtp delegates through the guard', () async {
    when(
      () => dataSource.verifyEmailOtp(any()),
    ).thenAnswer((_) => TaskEither.right(unit));

    final result = await repository
        .verifyEmailOtp(email: 'ops@sanad.ae', otp: '1234')
        .run();

    expect(result.isRight(), isTrue);
    verify(
      () => dataSource.verifyEmailOtp(
        const VerifyEmailRequest(email: 'ops@sanad.ae', otp: '1234'),
      ),
    ).called(1);
  });
}
