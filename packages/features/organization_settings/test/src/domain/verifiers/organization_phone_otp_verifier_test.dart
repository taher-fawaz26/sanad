import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organization_settings/src/domain/usecases/request_phone_otp_usecase.dart';
import 'package:organization_settings/src/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:organization_settings/src/domain/verifiers/organization_phone_otp_verifier.dart';

class _MockRequestUseCase extends Mock implements RequestPhoneOtpUseCase {}

class _MockVerifyUseCase extends Mock implements VerifyPhoneOtpUseCase {}

void main() {
  late _MockRequestUseCase requestOtp;
  late _MockVerifyUseCase verifyOtp;
  late OrganizationPhoneOtpVerifier verifier;

  const phone = '+971500000000';

  setUpAll(() {
    registerFallbackValue(const RequestPhoneOtpParams(phone: phone));
    registerFallbackValue(const VerifyPhoneOtpParams(phone: phone, otp: '1234'));
  });

  setUp(() {
    requestOtp = _MockRequestUseCase();
    verifyOtp = _MockVerifyUseCase();
    verifier = OrganizationPhoneOtpVerifier(
      phone: phone,
      requestOtp: requestOtp,
      verifyOtp: verifyOtp,
    );
  });

  test('requestCode maps a successful call to an OtpDelivery', () async {
    when(
      () => requestOtp(const RequestPhoneOtpParams(phone: phone)),
    ).thenAnswer((_) => TaskEither.right(unit));

    final result = await verifier.requestCode().run();

    expect(result.isRight(), isTrue);
  });

  test('requestCode propagates a failure', () async {
    when(() => requestOtp(any())).thenAnswer(
      (_) => TaskEither.left(const ServerFailure(message: 'boom')),
    );

    final result = await verifier.requestCode().run();

    expect(result.isLeft(), isTrue);
  });

  test('verifyCode delegates to the use case with the given code', () async {
    when(
      () => verifyOtp(const VerifyPhoneOtpParams(phone: phone, otp: '1234')),
    ).thenAnswer((_) => TaskEither.right(unit));

    final result = await verifier.verifyCode('1234').run();

    expect(result.isRight(), isTrue);
    verify(
      () => verifyOtp(const VerifyPhoneOtpParams(phone: phone, otp: '1234')),
    ).called(1);
  });
}
