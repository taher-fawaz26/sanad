import 'package:auth/auth.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_client/src/features/oauth/client_otp_request_cubit.dart';

class _MockRequestClientOtpUseCase extends Mock
    implements RequestClientOtpUseCase {}

void main() {
  late _MockRequestClientOtpUseCase requestOtp;

  setUpAll(() {
    registerFallbackValue(
      const ClientOtpParams(method: ClientAuthMethod.email, value: ''),
    );
  });

  setUp(() => requestOtp = _MockRequestClientOtpUseCase());

  ClientOtpRequestCubit build() => ClientOtpRequestCubit(requestOtp);

  blocTest<ClientOtpRequestCubit, ClientOtpRequestState>(
    'a successful request emits Ready and sends the exact method/value',
    build: build,
    setUp: () =>
        when(() => requestOtp(any())).thenReturn(TaskEither.right(null)),
    act: (cubit) => cubit.request(
      method: ClientAuthMethod.email,
      value: 'user@example.com',
    ),
    expect: () => [
      isA<ClientOtpRequestInProgress>(),
      isA<ClientOtpRequestReady>(),
    ],
    verify: (_) {
      final captured =
          verify(() => requestOtp(captureAny())).captured.single
              as ClientOtpParams;
      expect(captured.method, ClientAuthMethod.email);
      expect(captured.value, 'user@example.com');
    },
  );

  blocTest<ClientOtpRequestCubit, ClientOtpRequestState>(
    'a 429 (rate limit) is treated as Ready — a live code already exists',
    build: build,
    setUp: () => when(() => requestOtp(any())).thenReturn(
      TaskEither.left(const RateLimitFailure(message: 'errors.rate_limited')),
    ),
    act: (cubit) => cubit.request(
      method: ClientAuthMethod.phone,
      value: '+971501234567',
    ),
    expect: () => [
      isA<ClientOtpRequestInProgress>(),
      isA<ClientOtpRequestReady>(),
    ],
  );

  blocTest<ClientOtpRequestCubit, ClientOtpRequestState>(
    'a delivery failure (503) emits Failure and does not proceed',
    build: build,
    setUp: () => when(() => requestOtp(any())).thenReturn(
      TaskEither.left(const ServerFailure(message: 'errors.delivery_failed')),
    ),
    act: (cubit) => cubit.request(
      method: ClientAuthMethod.email,
      value: 'user@example.com',
    ),
    expect: () => [
      isA<ClientOtpRequestInProgress>(),
      isA<ClientOtpRequestFailure>(),
    ],
  );
}
