import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:forgot_password/src/domain/usecases/forgot_password_params.dart';
import 'package:forgot_password/src/domain/usecases/request_forgot_password_usecase.dart';
import 'package:forgot_password/src/domain/usecases/reset_password_usecase.dart';
import 'package:forgot_password/src/domain/usecases/verify_forgot_password_otp_usecase.dart';
import 'package:forgot_password/src/presentation/bloc/forgot_password_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockRequest extends Mock implements RequestForgotPasswordUseCase {}
class _MockVerify extends Mock implements VerifyForgotPasswordOtpUseCase {}
class _MockReset extends Mock implements ResetPasswordUseCase {}

void main() {
  late _MockRequest requestUseCase;
  late _MockVerify verifyUseCase;
  late _MockReset resetUseCase;

  setUp(() {
    requestUseCase = _MockRequest();
    verifyUseCase = _MockVerify();
    resetUseCase = _MockReset();
    registerFallbackValue(const ForgotPasswordRequestParams(identifier: ''));
    registerFallbackValue(const VerifyForgotPasswordOtpParams(identifier: '', otp: 0));
    registerFallbackValue(const ResetPasswordParams(identifier: '', password: ''));
  });

  ForgotPasswordBloc build() => ForgotPasswordBloc(
        requestForgotPasswordUseCase: requestUseCase,
        verifyForgotPasswordOtpUseCase: verifyUseCase,
        resetPasswordUseCase: resetUseCase,
      );

  group('ForgotPasswordRequestEvent', () {
    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits loading then otpSent on success',
      build: build,
      setUp: () {
        when(() => requestUseCase.call(any()))
            .thenReturn(TaskEither.right(unit));
      },
      act: (b) => b.add(const ForgotPasswordRequestEvent('user@test.com')),
      expect: () => [
        isA<ForgotPasswordRequestLoadingState>(),
        isA<ForgotPasswordOtpSentState>(),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits loading then requestFailure on failure',
      build: build,
      setUp: () {
        when(() => requestUseCase.call(any())).thenReturn(
          TaskEither.left(const NoInternetFailure(message: 'offline')),
        );
      },
      act: (b) => b.add(const ForgotPasswordRequestEvent('user@test.com')),
      expect: () => [
        isA<ForgotPasswordRequestLoadingState>(),
        isA<ForgotPasswordRequestFailureState>(),
      ],
    );
  });

  group('ForgotPasswordVerifyOtpEvent', () {
    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits verifyLoading then otpVerified on success',
      build: build,
      setUp: () {
        when(() => verifyUseCase.call(any()))
            .thenReturn(TaskEither.right(unit));
      },
      act: (b) => b.add(const ForgotPasswordVerifyOtpEvent('user@test.com', 12345)),
      expect: () => [
        isA<ForgotPasswordOtpVerifyLoadingState>(),
        isA<ForgotPasswordOtpVerifiedState>(),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits verifyLoading then otpFailure on failure',
      build: build,
      setUp: () {
        when(() => verifyUseCase.call(any())).thenReturn(
          TaskEither.left(const ServerFailure(message: 'invalid otp', code: '400')),
        );
      },
      act: (b) => b.add(const ForgotPasswordVerifyOtpEvent('user@test.com', 99999)),
      expect: () => [
        isA<ForgotPasswordOtpVerifyLoadingState>(),
        isA<ForgotPasswordOtpFailureState>(),
      ],
    );
  });

  group('ForgotPasswordResendOtpEvent', () {
    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits resendLoading then otpReady on success',
      build: build,
      setUp: () {
        when(() => requestUseCase.call(any()))
            .thenReturn(TaskEither.right(unit));
      },
      act: (b) => b.add(const ForgotPasswordResendOtpEvent('user@test.com')),
      expect: () => [
        isA<ForgotPasswordOtpResendLoadingState>(),
        isA<ForgotPasswordOtpReadyState>(),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits resendLoading then otpFailure on failure',
      build: build,
      setUp: () {
        when(() => requestUseCase.call(any())).thenReturn(
          TaskEither.left(const TimeoutFailure(message: 'timeout', code: 'timeout')),
        );
      },
      act: (b) => b.add(const ForgotPasswordResendOtpEvent('user@test.com')),
      expect: () => [
        isA<ForgotPasswordOtpResendLoadingState>(),
        isA<ForgotPasswordOtpFailureState>(),
      ],
    );
  });

  group('ForgotPasswordResetEvent', () {
    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits resetLoading then resetSuccess on success',
      build: build,
      setUp: () {
        when(() => resetUseCase.call(any()))
            .thenReturn(TaskEither.right(unit));
      },
      act: (b) => b.add(const ForgotPasswordResetEvent('user@test.com', 'newP@ss1')),
      expect: () => [
        isA<ForgotPasswordResetLoadingState>(),
        isA<ForgotPasswordResetSuccessState>(),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits resetLoading then resetFailure on failure',
      build: build,
      setUp: () {
        when(() => resetUseCase.call(any())).thenReturn(
          TaskEither.left(const ServerFailure(message: 'reset failed', code: '500')),
        );
      },
      act: (b) => b.add(const ForgotPasswordResetEvent('user@test.com', 'newP@ss1')),
      expect: () => [
        isA<ForgotPasswordResetLoadingState>(),
        isA<ForgotPasswordResetFailureState>(),
      ],
    );
  });
}
