import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:auth/src/data/models/user_model.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/enums/auth_session_status.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:auth/src/presentation/session/session_builder.dart';
import 'package:auth/src/presentation/session/session_context_extension.dart';
import 'package:auth/src/presentation/session/session_selector.dart';
import 'package:auth/src/session/session_cache.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:auth/src/session/session_repository.dart';
import 'package:auth/src/session/session_storage.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:storage/storage.dart';

class _MockTokenManager extends Mock implements TokenManager {}

class _MockHiveLocalStorage extends Mock implements HiveLocalStorage {}

const _tUser = UserModel(
  id: 'user-1',
  email: 'seed@sanad.test',
  isVerified: true,
  isActive: true,
  type: UserType.client,
);

const _tSession = AuthSessionEntity(
  accessToken: 'access-1',
  refreshToken: 'refresh-1',
  status: AuthSessionStatus.authenticated,
  isEmailVerified: true,
  isProfileCreated: true,
  user: _tUser,
  permissions: [],
);

SessionManager _buildManager(TokenManager tokenManager) {
  final hiveStorage = _MockHiveLocalStorage();
  when(
    () => hiveStorage.save(
      key: any(named: 'key'),
      value: any(named: 'value'),
      boxName: any(named: 'boxName'),
    ),
  ).thenAnswer((_) async {});

  final cache = SessionCache();
  final storage = SessionStorage(hiveStorage);
  final repository = SessionRepository(
    cache: cache,
    storage: storage,
    tokenManager: tokenManager,
  );
  return SessionManager(
    repository: repository,
    cache: cache,
    tokenManager: tokenManager,
    authStatusNotifier: AuthStatusNotifier(),
  );
}

void main() {
  late _MockTokenManager tokenManager;
  late SessionManager manager;

  setUp(() {
    tokenManager = _MockTokenManager();
    when(
      () => tokenManager.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => tokenManager.clearTokens()).thenAnswer((_) async {});
    when(() => tokenManager.accessToken).thenReturn('access-1');
    when(() => tokenManager.refreshToken).thenReturn('refresh-1');

    manager = _buildManager(tokenManager);
  });

  group('SessionBuilder', () {
    testWidgets('renders null then rebuilds after save', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionBuilder(
            sessionManager: manager,
            builder: (context, session) =>
                Text(session?.user.email ?? 'signed-out'),
          ),
        ),
      );

      expect(find.text('signed-out'), findsOneWidget);

      await manager.save(_tSession);
      await tester.pump();

      expect(find.text('seed@sanad.test'), findsOneWidget);
    });
  });

  group('SessionSelector', () {
    testWidgets('rebuilds only when the selected value changes', (
      tester,
    ) async {
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SessionSelector<String?>(
            sessionManager: manager,
            selector: (session) => session?.user.email,
            builder: (context, email) {
              buildCount++;
              return Text(email ?? 'signed-out');
            },
          ),
        ),
      );

      expect(find.text('signed-out'), findsOneWidget);
      expect(buildCount, 1);

      await manager.save(_tSession);
      await tester.pump();

      expect(find.text('seed@sanad.test'), findsOneWidget);
      expect(buildCount, 2);

      // A mutation that does NOT change the selected value (email) must not
      // trigger a rebuild.
      await manager.update((s) => s.copyWith(isEmailVerified: false));
      await tester.pump();

      expect(buildCount, 2);
    });
  });

  group('BuildContext.session', () {
    setUp(() {
      if (sl.isRegistered<SessionManager>()) sl.unregister<SessionManager>();
      sl.registerSingleton<SessionManager>(manager);
    });

    tearDown(() {
      if (sl.isRegistered<SessionManager>()) sl.unregister<SessionManager>();
    });

    testWidgets('resolves the DI-registered SessionManager', (tester) async {
      SessionManager? resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              resolved = context.session;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, same(manager));
    });
  });
}
