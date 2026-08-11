import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/otp.dart';
import 'package:otp/src/presentation/bloc/otp/otp_bloc.dart';

void main() {
  group('OtpBloc', () {
    OtpFlowConfig<String> configWith({
      required TaskEither<Failure, OtpDelivery> Function() onRequestCode,
      required TaskEither<Failure, String> Function(String code) onVerifyCode,
      bool autoSendOnStart = true,
    }) {
      return OtpFlowConfig<String>(
        channel: OtpChannel.email,
        destination: 'user@example.com',
        autoSendOnStart: autoSendOnStart,
        verifier: CallbackOtpVerifier<String>(
          onRequestCode: onRequestCode,
          onVerifyCode: onVerifyCode,
        ),
      );
    }

    blocTest<OtpBloc<String>, OtpState<String>>(
      'sends the code and starts the countdown on OtpStarted',
      build: () => OtpBloc<String>(
        config: configWith(
          onRequestCode: () => TaskEither.right(const OtpDelivery()),
          onVerifyCode: (_) => TaskEither.right('ok'),
        ),
      ),
      act: (bloc) => bloc.add(const OtpStarted()),
      expect: () => [
        isA<OtpState<String>>().having(
          (s) => s.phase,
          'phase',
          isA<OtpSending>(),
        ),
        isA<OtpState<String>>().having(
          (s) => s.phase,
          'phase',
          isA<OtpAwaitingInput>(),
        ),
        isA<OtpState<String>>().having(
          (s) => s.secondsRemaining,
          'secondsRemaining',
          greaterThan(0),
        ),
      ],
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'skips the initial send when autoSendOnStart is false',
      build: () => OtpBloc<String>(
        config: configWith(
          autoSendOnStart: false,
          onRequestCode: () => TaskEither.right(const OtpDelivery()),
          onVerifyCode: (_) => TaskEither.right('ok'),
        ),
      ),
      act: (bloc) => bloc.add(const OtpStarted()),
      expect: () => [
        isA<OtpState<String>>().having(
          (s) => s.phase,
          'phase',
          isA<OtpAwaitingInput>(),
        ),
        isA<OtpState<String>>().having(
          (s) => s.secondsRemaining,
          'secondsRemaining',
          greaterThan(0),
        ),
      ],
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'verifies a correct code and emits OtpVerifiedPhase with the result',
      build: () => OtpBloc<String>(
        config: configWith(
          autoSendOnStart: false,
          onRequestCode: () => TaskEither.right(const OtpDelivery()),
          onVerifyCode: (code) => TaskEither.right('session-$code'),
        ),
      ),
      seed: () => const OtpState<String>(phase: OtpAwaitingInput()),
      act: (bloc) => bloc.add(const OtpSubmitted('123456')),
      expect: () => [
        isA<OtpState<String>>().having(
          (s) => s.phase,
          'phase',
          isA<OtpVerifying>(),
        ),
        isA<OtpState<String>>()
            .having((s) => s.phase, 'phase', isA<OtpVerifiedPhase>())
            .having((s) => s.verifiedData, 'verifiedData', 'session-123456'),
      ],
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'treats a rejected code as invalid by default',
      build: () => OtpBloc<String>(
        config: configWith(
          autoSendOnStart: false,
          onRequestCode: () => TaskEither.right(const OtpDelivery()),
          onVerifyCode: (_) => TaskEither.left(
            const ValidationFailure(message: 'wrong code'),
          ),
        ),
      ),
      seed: () => const OtpState<String>(phase: OtpAwaitingInput()),
      act: (bloc) => bloc.add(const OtpSubmitted('000000')),
      expect: () => [
        isA<OtpState<String>>().having(
          (s) => s.phase,
          'phase',
          isA<OtpVerifying>(),
        ),
        isA<OtpState<String>>().having(
          (s) => s.phase,
          'phase',
          isA<OtpInvalidCode>(),
        ),
      ],
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'treats a failure carrying an expired code as OtpExpiredPhase',
      build: () => OtpBloc<String>(
        config: configWith(
          autoSendOnStart: false,
          onRequestCode: () => TaskEither.right(const OtpDelivery()),
          onVerifyCode: (_) => TaskEither.left(
            const ValidationFailure(message: 'expired', code: 'OTP_EXPIRED'),
          ),
        ),
      ),
      seed: () => const OtpState<String>(phase: OtpAwaitingInput()),
      act: (bloc) => bloc.add(const OtpSubmitted('123456')),
      expect: () => [
        isA<OtpState<String>>().having(
          (s) => s.phase,
          'phase',
          isA<OtpVerifying>(),
        ),
        isA<OtpState<String>>().having(
          (s) => s.phase,
          'phase',
          isA<OtpExpiredPhase>(),
        ),
      ],
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'ignores resend while the countdown has not elapsed',
      build: () => OtpBloc<String>(
        config: configWith(
          autoSendOnStart: false,
          onRequestCode: () => TaskEither.right(const OtpDelivery()),
          onVerifyCode: (_) => TaskEither.right('ok'),
        ),
      ),
      seed: () => const OtpState<String>(
        phase: OtpAwaitingInput(),
        secondsRemaining: 30,
      ),
      act: (bloc) => bloc.add(const OtpResendRequested()),
      expect: () => <OtpState<String>>[],
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'ignores a second submit while already verifying',
      build: () => OtpBloc<String>(
        config: configWith(
          autoSendOnStart: false,
          onRequestCode: () => TaskEither.right(const OtpDelivery()),
          onVerifyCode: (_) => TaskEither.right('ok'),
        ),
      ),
      seed: () => const OtpState<String>(phase: OtpVerifying()),
      act: (bloc) => bloc.add(const OtpSubmitted('123456')),
      expect: () => <OtpState<String>>[],
    );
  });
}
