import 'package:auth/src/authorization/authorization_signal.dart';
import 'package:auth/src/data/models/permission_model.dart';
import 'package:auth/src/data/models/user_model.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/enums/auth_session_status.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:auth/src/session/session_cache.dart';
import 'package:authorization/authorization.dart';
import 'package:flutter_test/flutter_test.dart';

const _tUser = UserModel(
  id: 'user-1',
  email: 'seed@sanad.test',
  isVerified: true,
  isActive: true,
  type: UserType.organizationProvider,
);

AuthSessionEntity _sessionWith({
  required List<PermissionModel> permissions,
  DateTime? permissionsSyncedAt,
}) => AuthSessionEntity(
  accessToken: 'access-1',
  refreshToken: 'refresh-1',
  status: AuthSessionStatus.authenticated,
  isEmailVerified: true,
  isProfileCreated: true,
  user: _tUser,
  permissions: permissions,
  permissionsSyncedAt: permissionsSyncedAt,
);

void main() {
  late SessionCache cache;
  late AuthorizationSignal signal;

  setUp(() {
    cache = SessionCache();
    signal = AuthorizationSignal(cache);
  });

  tearDown(() {
    signal.dispose();
    cache.dispose();
  });

  group('signed out (no session)', () {
    test('permissions is empty and isResolved is false', () {
      expect(signal.permissions, PermissionSet.empty);
      expect(signal.isResolved, isFalse);
    });

    test('can/canAny/canAll/satisfies all deny', () {
      expect(signal.can('provider:branch:view'), isFalse);
      expect(signal.canAny(['provider:branch:view']), isFalse);
      expect(signal.canAll(<String>[]), isFalse);
      expect(
        signal.satisfies(const PermissionRequirement.single('x')),
        isFalse,
      );
    });
  });

  group('a /me-sourced session (permissionsSyncedAt set)', () {
    test('isResolved is true and permissions reflect the session', () {
      cache.set(
        _sessionWith(
          permissions: const [PermissionModel(name: 'provider:branch:view')],
          permissionsSyncedAt: DateTime(2026),
        ),
      );

      expect(signal.isResolved, isTrue);
      expect(signal.can('provider:branch:view'), isTrue);
      expect(signal.can('provider:branch:update'), isFalse);
    });

    test('provider:* wildcard is honored end-to-end from the session', () {
      cache.set(
        _sessionWith(
          permissions: const [PermissionModel(name: 'provider:*')],
          permissionsSyncedAt: DateTime(2026),
        ),
      );

      expect(signal.can('provider:branch:view'), isTrue);
      expect(signal.can('provider:worker:create'), isTrue);
    });
  });

  group('a session saved without /me (e.g. invitation acceptance)', () {
    test(
      'isResolved is false even with a (placeholder) empty permission list',
      () {
        cache.set(_sessionWith(permissions: const []));

        expect(signal.isResolved, isFalse);
        expect(signal.permissions, PermissionSet.empty);
      },
    );

    test('can/satisfies deny by default while unresolved, never throwing', () {
      cache.set(_sessionWith(permissions: const []));

      expect(signal.can('provider:branch:view'), isFalse);
      expect(
        signal.satisfies(
          const PermissionRequirement.single('provider:branch:view'),
        ),
        isFalse,
      );
    });
  });

  group('notification behavior', () {
    test('notifies when a session with a synced snapshot is set', () {
      var notified = 0;
      signal.addListener(() => notified++);

      cache.set(
        _sessionWith(
          permissions: const [PermissionModel(name: 'provider:branch:view')],
          permissionsSyncedAt: DateTime(2026),
        ),
      );

      expect(notified, 1);
    });

    test('does not notify when re-set with an identical permission set', () {
      cache.set(
        _sessionWith(
          permissions: const [PermissionModel(name: 'provider:branch:view')],
          permissionsSyncedAt: DateTime(2026),
        ),
      );
      var notified = 0;
      signal.addListener(() => notified++);

      // Same permissions, same resolution — e.g. a re-fetch of /me that
      // returned an identical set, or an unrelated session mutation
      // (language, profile) that SessionCache still re-emits.
      cache.set(
        _sessionWith(
          permissions: const [PermissionModel(name: 'provider:branch:view')],
          permissionsSyncedAt: DateTime(2027),
        ),
      );

      expect(
        notified,
        0,
        reason:
            'permissionsSyncedAt itself is not part of the decision '
            'projection — only the resulting PermissionSet/isResolved pair '
            'is compared',
      );
    });

    test('notifies when permissions change to a different grant', () {
      cache.set(
        _sessionWith(
          permissions: const [PermissionModel(name: 'provider:branch:view')],
          permissionsSyncedAt: DateTime(2026),
        ),
      );
      var notified = 0;
      signal.addListener(() => notified++);

      cache.set(
        _sessionWith(
          permissions: const [PermissionModel(name: 'provider:branch:update')],
          permissionsSyncedAt: DateTime(2026),
        ),
      );

      expect(notified, 1);
    });

    test('notifies on logout — resets to empty/unresolved', () {
      cache.set(
        _sessionWith(
          permissions: const [PermissionModel(name: 'provider:branch:view')],
          permissionsSyncedAt: DateTime(2026),
        ),
      );
      var notified = 0;
      signal.addListener(() => notified++);

      cache.clear();

      expect(notified, 1);
      expect(signal.isResolved, isFalse);
      expect(signal.permissions, PermissionSet.empty);
    });

    test(
      'reflects an already-populated session immediately on construction',
      () {
        cache.set(
          _sessionWith(
            permissions: const [PermissionModel(name: 'provider:branch:view')],
            permissionsSyncedAt: DateTime(2026),
          ),
        );

        // A signal constructed AFTER the session was already set (e.g. app
        // restart with a restored session) must not require a change event to
        // reflect the current state — DI resolves it once, lazily.
        final freshSignal = AuthorizationSignal(cache);

        expect(freshSignal.isResolved, isTrue);
        expect(freshSignal.can('provider:branch:view'), isTrue);

        freshSignal.dispose();
      },
    );
  });
}
