import 'package:auth/auth.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_cubit.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_state.dart';

class _MockUpdateClientProfileUseCase extends Mock
    implements UpdateClientProfileUseCase {}

class _MockSessionManager extends Mock implements SessionManager {}

AuthSessionEntity _builder(AuthSessionEntity s) => s;

void main() {
  late _MockUpdateClientProfileUseCase updateProfile;
  late _MockSessionManager sessionManager;

  setUpAll(() {
    registerFallbackValue(const UpdateClientProfileParams(name: ''));
    registerFallbackValue(_builder);
  });

  setUp(() {
    updateProfile = _MockUpdateClientProfileUseCase();
    sessionManager = _MockSessionManager();
    when(() => sessionManager.update(any())).thenAnswer((_) async => null);
  });

  AccountSetupCubit build() => AccountSetupCubit(
    updateProfile: updateProfile,
    sessionManager: sessionManager,
  );

  const profile = ClientProfile(
    id: 'client-1',
    name: 'Mohamed Shahat',
    preferredLanguage: 'en',
  );

  blocTest<AccountSetupCubit, AccountSetupState>(
    'submitName PATCHes clients/me, refreshes the session, and succeeds',
    build: build,
    setUp: () =>
        when(() => updateProfile(any())).thenReturn(TaskEither.right(profile)),
    act: (cubit) => cubit.submitName('Mohamed Shahat'),
    expect: () => [
      isA<AccountSetupState>()
          .having((s) => s.status, 'status', RequestStatus.loading)
          .having((s) => s.name, 'name', 'Mohamed Shahat'),
      isA<AccountSetupState>()
          .having((s) => s.status, 'status', RequestStatus.success)
          .having((s) => s.name, 'name', 'Mohamed Shahat'),
    ],
    verify: (_) {
      final captured =
          verify(() => updateProfile(captureAny())).captured.single
              as UpdateClientProfileParams;
      expect(captured.name, 'Mohamed Shahat');
      verify(() => sessionManager.update(any())).called(1);
    },
  );

  blocTest<AccountSetupCubit, AccountSetupState>(
    'submitName failure preserves the entered name and skips session refresh',
    build: build,
    setUp: () => when(() => updateProfile(any())).thenReturn(
      TaskEither.left(const ServerFailure(message: 'boom')),
    ),
    act: (cubit) => cubit.submitName('Mohamed Shahat'),
    expect: () => [
      isA<AccountSetupState>().having(
        (s) => s.status,
        'status',
        RequestStatus.loading,
      ),
      isA<AccountSetupState>()
          .having((s) => s.status, 'status', RequestStatus.failure)
          .having((s) => s.name, 'name', 'Mohamed Shahat')
          .having((s) => s.failure, 'failure', isA<ServerFailure>()),
    ],
    verify: (_) => verifyNever(() => sessionManager.update(any())),
  );
}
