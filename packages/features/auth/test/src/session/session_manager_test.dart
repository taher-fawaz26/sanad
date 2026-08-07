import 'package:auth/src/auth/auth_status.dart';
import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:auth/src/data/models/permission_model.dart';
import 'package:auth/src/data/models/profiles/auth_profile_model.dart';
import 'package:auth/src/data/models/responses/auth_account_settings_response_dto.dart';
import 'package:auth/src/data/models/responses/auth_session_response_dto.dart';
import 'package:auth/src/data/models/user_model.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/worker_status.dart';
import 'package:auth/src/domain/enums/auth_session_status.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:auth/src/domain/enums/worker_type.dart';
import 'package:auth/src/session/session_cache.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:auth/src/session/session_repository.dart';
import 'package:auth/src/session/session_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';

class _MockTokenManager extends Mock implements TokenManager {}

/// In-memory [SessionStorage] backed by a Map — mirrors real Hive semantics
/// (write / read / delete of a JSON map) without touching disk.
class _FakeSessionStorage implements SessionStorage {
  Map<String, dynamic>? _saved;

  int reads = 0;
  int writes = 0;
  int deletes = 0;

  @override
  Future<AuthSessionEntity?> read() async {
    reads++;
    if (_saved == null) return null;
    // Rebuild via AuthSessionResponseModel to mirror production behaviour.
    // Import indirectly through the concrete class exposed here.
    return _sessionFromMap(_saved!);
  }

  @override
  Future<void> write(AuthSessionEntity session) async {
    writes++;
    _saved = _sessionToMap(session);
  }

  @override
  Future<void> delete() async {
    deletes++;
    _saved = null;
  }

  Map<String, dynamic>? get raw => _saved;
}

// ── Fixtures ────────────────────────────────────────────────────────────────

const _tUser = UserModel(
  id: 'user-1',
  email: 'seed@sanad.test',
  isVerified: true,
  isActive: true,
  type: UserType.companyProvider,
);

const _tProfile = BusinessProviderProfileModel(
  id: 'user-1',
  businessName: 'Sanad LLC',
  isReviewed: true,
);

const _tAccountSettings = AuthAccountSettingsModel(
  id: 'user-1',
  name: 'Layla',
  email: 'seed@sanad.test',
  preferredLanguage: 'ar',
);

const _tPermissions = [PermissionModel(name: '*')];

const _tSession = AuthSessionEntity(
  accessToken: 'access-1',
  refreshToken: 'refresh-1',
  status: AuthSessionStatus.authenticated,
  isEmailVerified: true,
  isProfileCreated: true,
  user: _tUser,
  profile: _tProfile,
  accountSettings: _tAccountSettings,
  permissions: _tPermissions,
);

void main() {
  late _MockTokenManager tokenManager;
  late SessionCache cache;
  late _FakeSessionStorage storage;
  late SessionRepository repository;
  late AuthStatusNotifier notifier;
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
    when(() => tokenManager.accessToken).thenReturn(null);
    when(() => tokenManager.refreshToken).thenReturn(null);

    cache = SessionCache();
    storage = _FakeSessionStorage();
    repository = SessionRepository(
      cache: cache,
      storage: storage,
      tokenManager: tokenManager,
    );
    notifier = AuthStatusNotifier();
    manager = SessionManager(
      repository: repository,
      cache: cache,
      tokenManager: tokenManager,
      authStatusNotifier: notifier,
    );
  });

  group('save → current → clear round-trip', () {
    test(
      'save persists to all three tiers and flips notifier authenticated',
      () async {
        // After save, TokenManager returns the persisted tokens.
        when(() => tokenManager.accessToken).thenReturn('access-1');
        when(() => tokenManager.refreshToken).thenReturn('refresh-1');

        await manager.save(_tSession);

        verify(
          () => tokenManager.saveTokens(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
          ),
        ).called(1);
        expect(storage.writes, 1);
        expect(cache.value, _tSession);
        expect(manager.current(), _tSession);
        expect(notifier.status, AuthStatus.authenticated);
        expect(notifier.isProfileCompleted, isTrue);
      },
    );

    test('clear wipes tokens, Hive, cache, and flips notifier', () async {
      when(() => tokenManager.accessToken).thenReturn('access-1');
      when(() => tokenManager.refreshToken).thenReturn('refresh-1');
      await manager.save(_tSession);

      await manager.clear();

      verify(() => tokenManager.clearTokens()).called(1);
      expect(storage.deletes, 1);
      expect(cache.value, isNull);
      expect(notifier.status, AuthStatus.unauthenticated);
    });

    test(
      'current returns null when TokenManager has no live tokens even if '
      'cache is populated (race with onUnauthorized)',
      () async {
        when(() => tokenManager.accessToken).thenReturn('access-1');
        when(() => tokenManager.refreshToken).thenReturn('refresh-1');
        await manager.save(_tSession);

        // Tokens got cleared out from underneath us.
        when(() => tokenManager.accessToken).thenReturn(null);
        when(() => tokenManager.refreshToken).thenReturn(null);

        expect(manager.current(), isNull);
      },
    );
  });

  group('token composition (silent refresh)', () {
    test(
      'current() reflects the latest TokenManager tokens without another save',
      () async {
        when(() => tokenManager.accessToken).thenReturn('access-1');
        when(() => tokenManager.refreshToken).thenReturn('refresh-1');
        await manager.save(_tSession);

        // Interceptor performs a silent refresh — TokenManager updates but
        // the SessionCache still holds the pre-refresh snapshot.
        when(() => tokenManager.accessToken).thenReturn('access-2');
        when(() => tokenManager.refreshToken).thenReturn('refresh-2');

        final current = manager.current()!;
        expect(current.accessToken, 'access-2');
        expect(current.refreshToken, 'refresh-2');
        // Everything else remains untouched.
        expect(current.user.email, 'seed@sanad.test');
        expect(current.accountSettings?.name, 'Layla');
      },
    );
  });

  group('update partial merge', () {
    setUp(() async {
      when(() => tokenManager.accessToken).thenReturn('access-1');
      when(() => tokenManager.refreshToken).thenReturn('refresh-1');
      await manager.save(_tSession);
      // Reset per-tier counters so update() metrics are clean.
      storage.writes = 0;
      clearInteractions(tokenManager);
      when(() => tokenManager.accessToken).thenReturn('access-1');
      when(() => tokenManager.refreshToken).thenReturn('refresh-1');
    });

    test(
      'accountSettings change: re-persists cache + Hive, leaves tokens alone',
      () async {
        const updated = AuthAccountSettingsModel(
          id: 'user-1',
          name: 'Layla New Name',
          email: 'seed@sanad.test',
          preferredLanguage: 'en',
        );

        final next = await manager.update(
          (s) => s.copyWith(accountSettings: updated),
        );

        expect(next?.accountSettings?.name, 'Layla New Name');
        expect(cache.value?.accountSettings, updated);
        expect(storage.writes, 1);
        verifyNever(
          () => tokenManager.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ),
        );
      },
    );

    test(
      'token rotation via update: re-persists tokens through TokenManager',
      () async {
        await manager.update(
          (s) => s.copyWith(
            accessToken: 'access-2',
            refreshToken: 'refresh-2',
          ),
        );

        verify(
          () => tokenManager.saveTokens(
            accessToken: 'access-2',
            refreshToken: 'refresh-2',
          ),
        ).called(1);
        expect(storage.writes, 1);
      },
    );

    test('update on empty session is a no-op returning null', () async {
      await manager.clear();
      expect(cache.value, isNull);

      final result = await manager.update((s) => s);

      expect(result, isNull);
    });
  });

  group('restore', () {
    test(
      'restores session from Hive + live tokens, flips notifier authenticated',
      () async {
        // Seed the fake Hive with a persisted snapshot.
        storage._saved = _sessionToMap(_tSession);
        when(() => tokenManager.accessToken).thenReturn('access-live');
        when(() => tokenManager.refreshToken).thenReturn('refresh-live');

        final restored = await manager.restore();

        expect(restored, isNotNull);
        // Live tokens override the persisted ones (models a silent refresh
        // that happened on a previous run).
        expect(restored!.accessToken, 'access-live');
        expect(restored.refreshToken, 'refresh-live');
        expect(restored.user.email, 'seed@sanad.test');
        expect(restored.accountSettings?.name, 'Layla');
        expect(cache.value, restored);
        expect(notifier.status, AuthStatus.authenticated);
      },
    );

    test(
      'no-op when Hive is empty — notifier stays unknown, cache stays null',
      () async {
        final restored = await manager.restore();

        expect(restored, isNull);
        expect(cache.value, isNull);
        expect(notifier.status, AuthStatus.unknown);
      },
    );

    test(
      'drops the persisted snapshot when tokens are missing (orphan Hive)',
      () async {
        storage._saved = _sessionToMap(_tSession);
        when(() => tokenManager.accessToken).thenReturn(null);
        when(() => tokenManager.refreshToken).thenReturn(null);

        final restored = await manager.restore();

        expect(restored, isNull);
        expect(cache.value, isNull);
        expect(storage.deletes, 1);
      },
    );
  });

  group('guard helpers', () {
    setUp(() async {
      when(() => tokenManager.accessToken).thenReturn('access-1');
      when(() => tokenManager.refreshToken).thenReturn('refresh-1');
      await manager.save(_tSession);
    });

    test('isAuthenticated / isEmailVerified / isProfileCompleted', () {
      expect(manager.isAuthenticated, isTrue);
      expect(manager.isEmailVerified, isTrue);
      expect(manager.isProfileCompleted, isTrue);
    });

    test('userType / isUserType', () {
      expect(manager.userType, UserType.companyProvider);
      expect(manager.isUserType(UserType.companyProvider), isTrue);
      expect(manager.isUserType(UserType.client), isFalse);
    });

    test('hasPermission wildcard grants everything', () {
      expect(manager.hasPermission('branch:view'), isTrue);
      expect(manager.hasPermission('anything'), isTrue);
    });

    test('hasPermission exact match', () async {
      const scoped = AuthSessionEntity(
        accessToken: 'access-2',
        refreshToken: 'refresh-2',
        status: AuthSessionStatus.authenticated,
        isEmailVerified: true,
        isProfileCreated: true,
        user: _tUser,
        permissions: [
          PermissionModel(name: 'branch:view'),
          PermissionModel(name: 'worker:create'),
        ],
      );
      when(() => tokenManager.accessToken).thenReturn('access-2');
      when(() => tokenManager.refreshToken).thenReturn('refresh-2');
      await manager.save(scoped);

      expect(manager.hasPermission('branch:view'), isTrue);
      expect(manager.hasPermission('worker:create'), isTrue);
      expect(manager.hasPermission('worker:delete'), isFalse);
      expect(
        manager.hasAnyPermission(['worker:delete', 'branch:view']),
        isTrue,
      );
      expect(
        manager.hasAnyPermission(['worker:delete', 'ghost']),
        isFalse,
      );
    });

    test('guard helpers all short-circuit to false when signed out', () async {
      await manager.clear();

      expect(manager.isAuthenticated, isFalse);
      expect(manager.isEmailVerified, isFalse);
      expect(manager.isProfileCompleted, isFalse);
      expect(manager.userType, isNull);
      expect(manager.hasPermission('branch:view'), isFalse);
      expect(manager.permissions, isEmpty);
      expect(manager.accountSettings, isNull);
      expect(manager.profile, isNull);
    });
  });

  group('derived display getters', () {
    setUp(() async {
      when(() => tokenManager.accessToken).thenReturn('access-1');
      when(() => tokenManager.refreshToken).thenReturn('refresh-1');
    });

    test(
      'provider with accountSettings.name: displayName is the owner name',
      () async {
        await manager.save(_tSession);
        expect(manager.displayName, 'Layla');
        expect(manager.businessName, 'Sanad LLC');
        expect(manager.email, 'seed@sanad.test');
        expect(manager.initials, 'L');
        expect(manager.avatar, isNull);
      },
    );

    test(
      'client falls back to profile fullName when no accountSettings',
      () async {
        const clientSession = AuthSessionEntity(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          status: AuthSessionStatus.authenticated,
          isEmailVerified: true,
          isProfileCreated: true,
          user: UserModel(
            id: 'client-1',
            email: 'client@sanad.test',
            isVerified: true,
            isActive: true,
            type: UserType.client,
          ),
          profile: ClientProfileModel(
            id: 'client-1',
            fullName: 'Jane Doe',
            email: 'client@sanad.test',
            emiratesId: '784-0000-0000000-0',
          ),
          permissions: [],
        );
        await manager.save(clientSession);

        expect(manager.displayName, 'Jane Doe');
        expect(manager.businessName, isNull);
        expect(manager.email, 'client@sanad.test');
        expect(manager.initials, 'JD');
      },
    );

    test('worker falls back to profile name and phoneNumber', () async {
      const workerSession = AuthSessionEntity(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        status: AuthSessionStatus.authenticated,
        isEmailVerified: true,
        isProfileCreated: true,
        user: UserModel(
          id: 'worker-1',
          email: 'worker@sanad.test',
          isVerified: true,
          isActive: true,
          type: UserType.worker,
        ),
        profile: WorkerProfileModel(
          id: 'worker-1',
          name: 'Sam Worker',
          phoneNumber: '+971500000009',
          jobTitle: 'Technician',
          type: WorkerType.worker,
          status: WorkerStatus.active,
        ),
        permissions: [],
      );
      await manager.save(workerSession);

      expect(manager.displayName, 'Sam Worker');
      expect(manager.phone, '+971500000009');
      expect(manager.initials, 'SW');
    });

    test('no profile and no accountSettings: everything null', () async {
      const bare = AuthSessionEntity(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        status: AuthSessionStatus.authenticated,
        isEmailVerified: true,
        isProfileCreated: false,
        user: UserModel(
          id: 'bare-1',
          email: 'bare@sanad.test',
          isVerified: true,
          isActive: true,
          type: UserType.client,
        ),
        permissions: [],
      );
      await manager.save(bare);

      expect(manager.displayName, isNull);
      expect(manager.businessName, isNull);
      expect(manager.phone, isNull);
      // email falls back to user.email even with no accountSettings.
      expect(manager.email, 'bare@sanad.test');
      expect(manager.initials, 'B');
    });
  });

  group('user type helpers', () {
    setUp(() async {
      when(() => tokenManager.accessToken).thenReturn('access-1');
      when(() => tokenManager.refreshToken).thenReturn('refresh-1');
      await manager.save(_tSession); // companyProvider
    });

    test('isProvider / isCompany true, isClient / isWorker false', () {
      expect(manager.isProvider, isTrue);
      expect(manager.isCompany, isTrue);
      expect(manager.isClient, isFalse);
      expect(manager.isWorker, isFalse);
    });
  });

  group('mutation helpers', () {
    setUp(() async {
      when(() => tokenManager.accessToken).thenReturn('access-1');
      when(() => tokenManager.refreshToken).thenReturn('refresh-1');
      await manager.save(_tSession);
    });

    test('setEmail updates accountSettings.email only', () async {
      final result = await manager.setEmail('new@sanad.test');

      expect(result?.accountSettings?.email, 'new@sanad.test');
      expect(manager.accountSettings?.email, 'new@sanad.test');
      // Untouched fields survive.
      expect(manager.accountSettings?.name, 'Layla');
    });

    test('setPhone(null) explicitly clears the phone', () async {
      await manager.setPhone('+971500000000');
      expect(manager.accountSettings?.phone, '+971500000000');

      await manager.setPhone(null);
      expect(manager.accountSettings?.phone, isNull);
    });

    test('setLanguage updates preferredLanguage only', () async {
      await manager.setLanguage('en');
      expect(manager.accountSettings?.preferredLanguage, 'en');
      expect(manager.accountSettings?.email, 'seed@sanad.test');
    });

    test('setProfile replaces the whole profile', () async {
      const newProfile = BusinessProviderProfileModel(
        id: 'user-1',
        businessName: 'Renamed LLC',
        isReviewed: false,
      );
      await manager.setProfile(newProfile);

      expect(manager.businessName, 'Renamed LLC');
      expect(
        (manager.profile! as BusinessProviderProfileModel).isReviewed,
        isFalse,
      );
    });

    test('setPermissions replaces the granted permissions', () async {
      await manager.setPermissions(const [
        PermissionModel(name: 'branch:view'),
      ]);

      expect(manager.hasPermission('branch:view'), isTrue);
      expect(manager.hasPermission('worker:create'), isFalse);
    });

    test(
      'account-settings mutations no-op on a session without accountSettings',
      () async {
        const workerSession = AuthSessionEntity(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          status: AuthSessionStatus.authenticated,
          isEmailVerified: true,
          isProfileCreated: true,
          user: UserModel(
            id: 'worker-1',
            email: 'worker@sanad.test',
            isVerified: true,
            isActive: true,
            type: UserType.worker,
          ),
          permissions: [],
        );
        await manager.save(workerSession);

        final result = await manager.setEmail('irrelevant@sanad.test');

        expect(result, isNull);
        expect(manager.accountSettings, isNull);
      },
    );
  });

  group('watch()', () {
    test('emits when save/update/clear mutate the cache', () async {
      when(() => tokenManager.accessToken).thenReturn('access-1');
      when(() => tokenManager.refreshToken).thenReturn('refresh-1');

      final events = <AuthSessionEntity?>[];
      manager.watch().addListener(() {
        events.add(manager.watch().value);
      });

      await manager.save(_tSession);
      await manager.update((s) => s.copyWith(isEmailVerified: false));
      await manager.clear();

      expect(events, hasLength(3));
      expect(events[0]?.accessToken, 'access-1');
      expect(events[1]?.isEmailVerified, isFalse);
      expect(events[2], isNull);
    });
  });
}

/// Serialises [session] the same way [SessionStorage] does — routed through
/// the round-trippable [AuthSessionResponseModel].
Map<String, dynamic> _sessionToMap(AuthSessionEntity session) {
  final asModel = AuthSessionResponseModel(
    accessToken: session.accessToken,
    refreshToken: session.refreshToken,
    status: session.status,
    isEmailVerified: session.isEmailVerified,
    isProfileCreated: session.isProfileCreated,
    user: session.user,
    permissions: session.permissions,
    profile: session.profile,
    accountSettings: session.accountSettings,
  );
  return asModel.toJson();
}

/// Deserialises a stored map into an [AuthSessionEntity], mirroring the
/// production [SessionStorage.read] path.
AuthSessionEntity _sessionFromMap(Map<String, dynamic> raw) {
  return AuthSessionResponseModel.fromJson(raw);
}
