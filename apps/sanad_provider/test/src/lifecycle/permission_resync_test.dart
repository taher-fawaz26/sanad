import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_provider/src/lifecycle/permission_resync.dart';

class _MockSessionManager extends Mock implements SessionManager {}

class _MockGetCurrentUserUseCase extends Mock
    implements GetCurrentUserUseCase {}

const _tIdentity = AuthIdentity(
  id: 'user-1',
  email: 'seed@sanad.test',
  userType: UserType.organizationProvider,
  permissions: ['provider:branch:view'],
);

void main() {
  late _MockSessionManager sessionManager;
  late _MockGetCurrentUserUseCase getCurrentUserUseCase;
  late PermissionResync resync;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(_tIdentity);
  });

  setUp(() {
    sessionManager = _MockSessionManager();
    getCurrentUserUseCase = _MockGetCurrentUserUseCase();
    resync = PermissionResync(
      sessionManager: sessionManager,
      getCurrentUserUseCase: getCurrentUserUseCase,
    );
  });

  test('no-ops (does not call /me) when signed out', () async {
    when(() => sessionManager.isAuthenticated).thenReturn(false);

    await resync();

    verifyNever(() => getCurrentUserUseCase(any()));
  });

  test('hydrates the session from /me when signed in', () async {
    when(() => sessionManager.isAuthenticated).thenReturn(true);
    when(
      () => getCurrentUserUseCase(any()),
    ).thenReturn(TaskEither.right(_tIdentity));
    when(
      () => sessionManager.hydrateIdentity(any()),
    ).thenAnswer((_) async => null);

    await resync();

    verify(() => sessionManager.hydrateIdentity(_tIdentity)).called(1);
  });

  test(
    'a failed /me call is swallowed — hydrateIdentity is not called',
    () async {
      when(() => sessionManager.isAuthenticated).thenReturn(true);
      when(() => getCurrentUserUseCase(any())).thenReturn(
        TaskEither.left(const UnknownFailure(message: 'offline')),
      );

      await resync();

      verifyNever(() => sessionManager.hydrateIdentity(any()));
    },
  );
}
