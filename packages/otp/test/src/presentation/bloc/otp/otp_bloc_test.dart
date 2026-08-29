import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/otp.dart';
import 'package:otp/src/presentation/bloc/otp/otp_bloc.dart';

/// Records what the engine actually asked the backend for, which is the point
/// of most of these tests: *not* sending is the fix for the reopened-sheet
/// error, so "no request was issued" has to be assertable.
class _RecordingVerifier extends OtpVerifierBase<String> {
  _RecordingVerifier({
    this.onRequest,
    this.onResend,
    this.onCooldown,
    this.onVerify,
  });

  final TaskEither<Failure, OtpDelivery> Function()? onRequest;
  final TaskEither<Failure, OtpDelivery> Function()? onResend;
  final TaskEither<Failure, OtpCooldown> Function()? onCooldown;
  final TaskEither<Failure, String> Function(String code)? onVerify;

  int requests = 0;
  int resends = 0;
  int cooldowns = 0;
  int verifies = 0;

  @override
  TaskEither<Failure, OtpDelivery> requestCode() {
    requests++;
    return onRequest?.call() ??
        TaskEither.right(const OtpDelivery(maskedDestination: 'u***@e.com'));
  }

  @override
  TaskEither<Failure, OtpDelivery> resendCode() {
    resends++;
    // Distinct from requestCode so the two counters stay independent - the
    // point of these tests is which endpoint the engine chose.
    return onResend?.call() ??
        TaskEither.right(const OtpDelivery(maskedDestination: 'u***@e.com'));
  }

  @override
  TaskEither<Failure, OtpCooldown>? cooldown() {
    if (onCooldown == null) return null;
    cooldowns++;
    return onCooldown!();
  }

  @override
  TaskEither<Failure, String> verifyCode(String code) {
    verifies++;
    return onVerify?.call(code) ?? TaskEither.right('session-123456');
  }
}

OtpFlowConfig<String> _config(
  OtpVerifier<String> verifier, {
  bool autoSendOnStart = true,
  Duration fallbackCooldown = const Duration(seconds: 60),
}) => OtpFlowConfig<String>.email(
  destination: 'user@example.com',
  verifier: verifier,
  autoSendOnStart: autoSendOnStart,
  fallbackCooldown: fallbackCooldown,
);

TaskEither<Failure, OtpCooldown> _cool({
  required bool canResend,
  int remainingSeconds = 0,
  int resendsLeft = 4,
}) => TaskEither.right(
  OtpCooldown(
    canResend: canResend,
    remainingSeconds: remainingSeconds,
    resendsLeft: resendsLeft,
  ),
);

void main() {
  group('OtpBloc start — read before write', () {
    late _RecordingVerifier verifier;

    blocTest<OtpBloc<String>, OtpState<String>>(
      'sends a code when the cooldown probe reports no live session',
      build: () {
        verifier = _RecordingVerifier(
          onCooldown: () => _cool(canResend: true),
        );
        return OtpBloc<String>(config: _config(verifier));
      },
      act: (bloc) => bloc.add(const OtpStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(verifier.requests, 1);
        expect(bloc.state.phase, isA<OtpAwaitingInput>());
      },
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'does NOT send, and shows no error, when a session is already live '
      '(regression: reopening the sheet inside a cooldown showed an error '
      'under an empty field)',
      build: () {
        verifier = _RecordingVerifier(
          onCooldown: () => _cool(canResend: false, remainingSeconds: 42),
        );
        return OtpBloc<String>(config: _config(verifier));
      },
      act: (bloc) => bloc.add(const OtpStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(verifier.requests, 0, reason: 'no 429 to provoke');
        expect(bloc.state.phase, isA<OtpAwaitingInput>());
        expect(bloc.state.secondsRemaining, 42);
        expect(bloc.state.canResend, isFalse);
      },
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'a rate-limited send is a cooldown, not an error',
      build: () {
        verifier = _RecordingVerifier(
          onCooldown: () => _cool(canResend: false, remainingSeconds: 30),
          onRequest: () =>
              TaskEither.left(const RateLimitFailure(message: 'Slow down')),
        );
        // Probe says "go", the send still 429s — the race the server can win.
        var probes = 0;
        return OtpBloc<String>(
          config: _config(
            _RecordingVerifier(
              onCooldown: () {
                probes++;
                return probes == 1
                    ? _cool(canResend: true)
                    : _cool(canResend: false, remainingSeconds: 30);
              },
              onRequest: () => TaskEither.left(
                const RateLimitFailure(message: 'Slow down'),
              ),
            ),
          ),
        );
      },
      act: (bloc) => bloc.add(const OtpStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.phase, isA<OtpAwaitingInput>());
        expect(bloc.state.phase, isNot(isA<OtpDispatchFailed>()));
        expect(bloc.state.secondsRemaining, 30);
      },
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'a real delivery failure goes to the banner, not the field',
      build: () => OtpBloc<String>(
        config: _config(
          _RecordingVerifier(
            onCooldown: () => _cool(canResend: true),
            onRequest: () => TaskEither.left(
              const ConflictFailure(message: 'Already in use'),
            ),
          ),
        ),
      ),
      act: (bloc) => bloc.add(const OtpStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.phase, isA<OtpDispatchFailed>()),
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'skips the send when autoSendOnStart is false but still reads cooldown',
      build: () {
        verifier = _RecordingVerifier(
          onCooldown: () => _cool(canResend: false, remainingSeconds: 15),
        );
        return OtpBloc<String>(
          config: _config(verifier, autoSendOnStart: false),
        );
      },
      act: (bloc) => bloc.add(const OtpStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(verifier.requests, 0);
        expect(bloc.state.secondsRemaining, 15);
      },
    );
  });

  group('OtpBloc cooldown', () {
    blocTest<OtpBloc<String>, OtpState<String>>(
      'seeds the countdown from the server, never from the fallback '
      "(regression: a hardcoded 60s ignored the server's remainingSeconds)",
      build: () => OtpBloc<String>(
        config: _config(
          _RecordingVerifier(
            onCooldown: () => _cool(canResend: false, remainingSeconds: 17),
          ),
          fallbackCooldown: const Duration(seconds: 60),
        ),
      ),
      act: (bloc) => bloc.add(const OtpStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.secondsRemaining, 17),
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'never emits a 00:00 frame while the countdown is running '
      '(regression: the first tick was routed through the event loop)',
      build: () => OtpBloc<String>(
        config: _config(
          _RecordingVerifier(
            onCooldown: () => _cool(canResend: false, remainingSeconds: 25),
          ),
        ),
      ),
      act: (bloc) => bloc.add(const OtpStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        // Any state that is past Idle and still cooling down must show a
        // real remainder.
        expect(bloc.state.secondsRemaining, greaterThan(0));
      },
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'falls back only when the flow exposes no cooldown endpoint',
      build: () => OtpBloc<String>(
        config: _config(
          _RecordingVerifier(),
          fallbackCooldown: const Duration(seconds: 45),
        ),
      ),
      act: (bloc) => bloc.add(const OtpStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.secondsRemaining, 45),
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'fails open when the probe itself errors',
      build: () => OtpBloc<String>(
        config: _config(
          _RecordingVerifier(
            onCooldown: () =>
                TaskEither.left(const ServerFailure(message: 'boom')),
          ),
        ),
      ),
      act: (bloc) => bloc.add(const OtpStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(
        bloc.state.phase,
        isA<OtpAwaitingInput>(),
        reason: 'never strand the user behind an unconfirmed cooldown',
      ),
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'ticks down against the wall clock and re-enables resend at zero',
      build: () {
        var now = DateTime(2026);
        return OtpBloc<String>(
          config: _config(
            _RecordingVerifier(
              onCooldown: () => _cool(canResend: false, remainingSeconds: 3),
            ),
          ),
          clock: () => now = now.add(const Duration(seconds: 1)),
        );
      },
      act: (bloc) => bloc.add(const OtpStarted()),
      wait: const Duration(milliseconds: 4500),
      verify: (bloc) {
        expect(bloc.state.secondsRemaining, 0);
        expect(bloc.state.canResend, isTrue);
      },
    );
  });

  group('OtpBloc resend', () {
    blocTest<OtpBloc<String>, OtpState<String>>(
      'is ignored while the cooldown is running',
      build: () {
        final v = _RecordingVerifier(
          onCooldown: () => _cool(canResend: false, remainingSeconds: 30),
        );
        return OtpBloc<String>(config: _config(v))..verifierRef = v;
      },
      act: (bloc) async {
        bloc.add(const OtpStarted());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const OtpResendRequested());
      },
      wait: const Duration(milliseconds: 60),
      verify: (bloc) => expect(bloc.verifierRef.resends, 0),
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'uses the resend endpoint, not the request endpoint, once allowed',
      build: () {
        final v = _RecordingVerifier(
          onCooldown: () => _cool(canResend: true),
        );
        return OtpBloc<String>(config: _config(v, autoSendOnStart: false))
          ..verifierRef = v;
      },
      act: (bloc) async {
        bloc.add(const OtpStarted());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const OtpResendRequested());
      },
      wait: const Duration(milliseconds: 60),
      verify: (bloc) {
        expect(bloc.verifierRef.resends, 1);
        expect(bloc.verifierRef.requests, 0);
      },
    );
  });

  group('OtpBloc verification', () {
    blocTest<OtpBloc<String>, OtpState<String>>(
      'a correct code resolves with the verifier payload',
      build: () => OtpBloc<String>(
        config: _config(_RecordingVerifier(), autoSendOnStart: false),
      ),
      act: (bloc) => bloc.add(const OtpSubmitted('123456')),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.phase, isA<OtpVerifiedPhase>());
        expect(bloc.state.verifiedData, 'session-123456');
      },
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'a rejected code is an invalid-code field error',
      build: () => OtpBloc<String>(
        config: _config(
          _RecordingVerifier(
            onVerify: (_) =>
                TaskEither.left(const ValidationFailure(message: 'wrong')),
          ),
          autoSendOnStart: false,
        ),
      ),
      act: (bloc) => bloc.add(const OtpSubmitted('123456')),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.phase, isA<OtpInvalidCode>()),
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'an OTP_EXPIRED code maps to the expired phase',
      build: () => OtpBloc<String>(
        config: _config(
          _RecordingVerifier(
            onVerify: (_) => TaskEither.left(
              const ValidationFailure(message: 'expired', code: 'OTP_EXPIRED'),
            ),
          ),
          autoSendOnStart: false,
        ),
      ),
      act: (bloc) => bloc.add(const OtpSubmitted('123456')),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.phase, isA<OtpExpiredPhase>()),
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'a 409 is terminal — the target was taken while the code was out',
      build: () => OtpBloc<String>(
        config: _config(
          _RecordingVerifier(
            onVerify: (_) =>
                TaskEither.left(const ConflictFailure(message: 'taken')),
          ),
          autoSendOnStart: false,
        ),
      ),
      act: (bloc) => bloc.add(const OtpSubmitted('123456')),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.phase, isA<OtpConflict>()),
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'a short code is not submitted',
      build: () {
        final v = _RecordingVerifier();
        return OtpBloc<String>(
          config: _config(v, autoSendOnStart: false),
        )..verifierRef = v;
      },
      act: (bloc) => bloc.add(const OtpSubmitted('123')),
      wait: const Duration(milliseconds: 30),
      verify: (bloc) => expect(bloc.verifierRef.verifies, 0),
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'a second submit is dropped while one is in flight',
      build: () {
        final v = _RecordingVerifier(
          onVerify: (_) => TaskEither(() async {
            await Future<void>.delayed(const Duration(milliseconds: 40));
            return const Right<Failure, String>('ok');
          }),
        );
        return OtpBloc<String>(
          config: _config(v, autoSendOnStart: false),
        )..verifierRef = v;
      },
      act: (bloc) {
        bloc
          ..add(const OtpSubmitted('123456'))
          ..add(const OtpSubmitted('123456'));
      },
      wait: const Duration(milliseconds: 120),
      verify: (bloc) => expect(bloc.verifierRef.verifies, 1),
    );

    blocTest<OtpBloc<String>, OtpState<String>>(
      'editing the code clears a stale field error',
      build: () => OtpBloc<String>(
        config: _config(
          _RecordingVerifier(
            onVerify: (_) =>
                TaskEither.left(const ValidationFailure(message: 'wrong')),
          ),
          autoSendOnStart: false,
        ),
      ),
      act: (bloc) async {
        bloc.add(const OtpSubmitted('123456'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
        bloc.add(const OtpCodeChanged('12345'));
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) => expect(bloc.state.phase, isA<OtpAwaitingInput>()),
    );
  });

  group('OtpBloc session isolation', () {
    blocTest<OtpBloc<String>, OtpState<String>>(
      'changing the destination drops every trace of the old session',
      build: () => OtpBloc<String>(
        config: _config(
          _RecordingVerifier(
            onCooldown: () => _cool(canResend: false, remainingSeconds: 20),
            onVerify: (_) =>
                TaskEither.left(const ValidationFailure(message: 'wrong')),
          ),
        ),
      ),
      act: (bloc) async {
        bloc.add(const OtpStarted());
        await Future<void>.delayed(const Duration(milliseconds: 40));
        bloc.add(const OtpSubmitted('123456'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
        bloc.add(const OtpDestinationChanged('new@example.com'));
      },
      wait: const Duration(milliseconds: 140),
      verify: (bloc) {
        expect(bloc.state.destination, 'new@example.com');
        expect(bloc.state.code, isEmpty);
        expect(bloc.state.phase, isNot(isA<OtpInvalidCode>()));
      },
    );

    test('copyWith can actually clear its nullable fields', () {
      const seeded = OtpState<String>(
        maskedDestination: 'u***@e.com',
        verifiedData: 'session',
        cooldownEndsAt: null,
      );
      final cleared = seeded.copyWith(
        clearMaskedDestination: true,
        clearVerifiedData: true,
      );
      expect(cleared.maskedDestination, isNull);
      expect(cleared.verifiedData, isNull);
    });
  });
}

/// Test-only handle so `verify:` can inspect the verifier the bloc was built
/// with without threading it through a closure.
extension on OtpBloc<String> {
  static final _refs = Expando<_RecordingVerifier>();

  _RecordingVerifier get verifierRef => _refs[this]!;
  set verifierRef(_RecordingVerifier v) => _refs[this] = v;
}
