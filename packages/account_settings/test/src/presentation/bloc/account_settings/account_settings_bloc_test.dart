import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/enums/preferred_language.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:account_settings/src/domain/usecases/refresh_account_profile_usecase.dart';
import 'package:account_settings/src/domain/usecases/update_account_settings_usecase.dart';
import 'package:account_settings/src/presentation/bloc/account_settings/account_settings_bloc.dart';
import 'package:auth/auth.dart'
    show AuthAccountSettingsEntity, AuthSessionEntity, SessionManager, UserType;
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockUpdateAccountSettingsUseCase extends Mock
    implements UpdateAccountSettingsUseCase {}

class _MockRefreshAccountProfileUseCase extends Mock
    implements RefreshAccountProfileUseCase {}

class _MockSessionManager extends Mock implements SessionManager {}

// Identity builder used as the mocktail fallback for `SessionManager.update`,
// which takes an `AuthSessionEntity Function(AuthSessionEntity)`.
AuthSessionEntity _identityBuilder(AuthSessionEntity s) => s;

const _seedAuthSettings = AuthAccountSettingsEntity(
  id: 'e3521ee5-3f43-4af1-819b-8c0f1f164a5f',
  name: 'Layla Al Mansoori',
  email: 'seed-company-provider-1@sanad.test',
  preferredLanguage: 'ar',
);

const _seededSettings = AccountSettingsEntity(
  id: 'e3521ee5-3f43-4af1-819b-8c0f1f164a5f',
  name: 'Layla Al Mansoori',
  email: 'seed-company-provider-1@sanad.test',
  preferredLanguage: PreferredLanguage.ar,
);

const _refreshedAuthSettings = AuthAccountSettingsEntity(
  id: 'e3521ee5-3f43-4af1-819b-8c0f1f164a5f',
  name: 'Layla Al Mansoori',
  email: 'seed-company-provider-1@sanad.test',
  preferredLanguage: 'en',
);

const _refreshedSettings = AccountSettingsEntity(
  id: 'e3521ee5-3f43-4af1-819b-8c0f1f164a5f',
  name: 'Layla Al Mansoori',
  email: 'seed-company-provider-1@sanad.test',
  preferredLanguage: PreferredLanguage.en,
);

void main() {
  late _MockUpdateAccountSettingsUseCase updateAccountSettings;
  late _MockRefreshAccountProfileUseCase refreshAccountProfile;
  late _MockSessionManager sessionManager;

  setUpAll(() {
    registerFallbackValue(
      const UpdateAccountSettingsParams(
        preferredLanguage: PreferredLanguage.ar,
      ),
    );
    registerFallbackValue(_identityBuilder);
    registerFallbackValue(const NoParams());
    registerFallbackValue(UserType.client);
  });

  setUp(() {
    updateAccountSettings = _MockUpdateAccountSettingsUseCase();
    refreshAccountProfile = _MockRefreshAccountProfileUseCase();
    sessionManager = _MockSessionManager();
    when(() => sessionManager.update(any())).thenAnswer((_) async => null);
    // Default: background refresh fails silently — most tests below aren't
    // exercising it, so this keeps their expectations to seed-only emissions.
    when(() => refreshAccountProfile(any())).thenAnswer(
      (_) => TaskEither.left(const ServerFailure(message: 'unreachable')),
    );
  });

  AccountSettingsBloc build() => AccountSettingsBloc(
    updateAccountSettings: updateAccountSettings,
    refreshAccountProfile: refreshAccountProfile,
    sessionManager: sessionManager,
  );

  blocTest<AccountSettingsBloc, AccountSettingsState>(
    'AccountSettingsLoaded seeds from session instantly, then attempts a '
    'background persona-profile refresh',
    build: () {
      when(
        () => sessionManager.accountSettings,
      ).thenReturn(_seedAuthSettings);
      return build();
    },
    act: (bloc) => bloc.add(const AccountSettingsLoaded()),
    expect: () => [
      isA<AccountSettingsState>()
          .having((s) => s.loadStatus, 'loadStatus', RequestStatus.success)
          .having((s) => s.settings, 'settings', _seededSettings),
    ],
    verify: (_) {
      verify(() => refreshAccountProfile(any())).called(1);
    },
  );

  blocTest<AccountSettingsBloc, AccountSettingsState>(
    'AccountSettingsLoaded with no session emits success but null settings',
    build: () {
      when(() => sessionManager.accountSettings).thenReturn(null);
      return build();
    },
    act: (bloc) => bloc.add(const AccountSettingsLoaded()),
    expect: () => [
      isA<AccountSettingsState>()
          .having((s) => s.loadStatus, 'loadStatus', RequestStatus.success)
          .having((s) => s.settings, 'settings', isNull),
    ],
  );

  blocTest<AccountSettingsBloc, AccountSettingsState>(
    'a successful background refresh syncs the session and re-emits',
    build: () {
      // Mimics the real SessionManager: `accountSettings` reflects whatever
      // the last `update()` call wrote, so the post-refresh reseed observes
      // the synced value.
      var current = _seedAuthSettings;
      when(() => sessionManager.accountSettings).thenAnswer((_) => current);
      when(() => sessionManager.update(any())).thenAnswer((_) async {
        current = _refreshedAuthSettings;
        return null;
      });
      when(() => refreshAccountProfile(any())).thenAnswer(
        (_) => TaskEither.right(_refreshedSettings),
      );
      return build();
    },
    act: (bloc) => bloc.add(const AccountSettingsLoaded()),
    expect: () => [
      isA<AccountSettingsState>()
          .having((s) => s.loadStatus, 'loadStatus', RequestStatus.success)
          .having((s) => s.settings, 'settings', _seededSettings),
      isA<AccountSettingsState>()
          .having((s) => s.loadStatus, 'loadStatus', RequestStatus.success)
          .having((s) => s.settings, 'settings', _refreshedSettings),
    ],
    verify: (_) {
      verify(() => sessionManager.update(any())).called(1);
    },
  );

  blocTest<AccountSettingsBloc, AccountSettingsState>(
    'AccountSettingsRefreshed reseeds from the session snapshot and also '
    'attempts a background refresh',
    build: () {
      when(
        () => sessionManager.accountSettings,
      ).thenReturn(_refreshedAuthSettings);
      return build();
    },
    act: (bloc) => bloc.add(const AccountSettingsRefreshed()),
    expect: () => [
      isA<AccountSettingsState>()
          .having((s) => s.loadStatus, 'loadStatus', RequestStatus.success)
          .having((s) => s.settings, 'settings', _refreshedSettings),
    ],
    verify: (_) {
      verify(() => refreshAccountProfile(any())).called(1);
    },
  );

  blocTest<AccountSettingsBloc, AccountSettingsState>(
    'AccountSettingsRefreshed with no session emits success but '
    'null settings',
    build: () {
      when(() => sessionManager.accountSettings).thenReturn(null);
      return build();
    },
    act: (bloc) => bloc.add(const AccountSettingsRefreshed()),
    expect: () => [
      isA<AccountSettingsState>()
          .having((s) => s.loadStatus, 'loadStatus', RequestStatus.success)
          .having((s) => s.settings, 'settings', isNull),
    ],
  );

  blocTest<AccountSettingsBloc, AccountSettingsState>(
    'update persists settings, updates state, and syncs the session',
    build: build,
    setUp: () {
      when(() => updateAccountSettings(any(), any())).thenAnswer(
        (_) => TaskEither.right(_refreshedSettings),
      );
    },
    act: (bloc) => bloc.add(
      const AccountSettingsUpdated(
        UpdateAccountSettingsParams(
          preferredLanguage: PreferredLanguage.en,
        ),
      ),
    ),
    expect: () => [
      isA<AccountSettingsState>().having(
        (s) => s.saveStatus,
        'saveStatus',
        RequestStatus.loading,
      ),
      isA<AccountSettingsState>()
          .having((s) => s.saveStatus, 'saveStatus', RequestStatus.success)
          .having((s) => s.settings, 'settings', _refreshedSettings),
    ],
    verify: (_) {
      verify(() => sessionManager.update(any())).called(1);
    },
  );

  blocTest<AccountSettingsBloc, AccountSettingsState>(
    'update failure surfaces the failure',
    build: build,
    setUp: () {
      when(() => updateAccountSettings(any(), any())).thenAnswer(
        (_) => TaskEither.left(const ServerFailure(message: 'boom')),
      );
    },
    act: (bloc) => bloc.add(
      const AccountSettingsUpdated(
        UpdateAccountSettingsParams(
          preferredLanguage: PreferredLanguage.en,
        ),
      ),
    ),
    verify: (bloc) {
      expect(bloc.state.saveStatus, RequestStatus.failure);
      expect(bloc.state.saveFailure, isA<ServerFailure>());
      verifyNever(() => sessionManager.update(any()));
    },
  );

  group('AccountSettingsLanguageSynced (best-effort background sync)', () {
    blocTest<AccountSettingsBloc, AccountSettingsState>(
      'never touches saveStatus, so no blocking progress dialog is shown',
      build: () {
        when(
          () => sessionManager.userType,
        ).thenReturn(UserType.organizationProvider);
        when(
          () => updateAccountSettings(any(), any()),
        ).thenAnswer((_) => TaskEither.right(_refreshedSettings));
        return build();
      },
      act: (bloc) =>
          bloc.add(const AccountSettingsLanguageSynced(PreferredLanguage.en)),
      expect: () => [
        isA<AccountSettingsState>()
            .having((s) => s.saveStatus, 'saveStatus', RequestStatus.initial)
            .having((s) => s.languageSyncFailure, 'languageSyncFailure', isNull)
            .having((s) => s.settings, 'settings', _refreshedSettings),
      ],
      verify: (_) => verify(() => sessionManager.update(any())).called(1),
    );

    blocTest<AccountSettingsBloc, AccountSettingsState>(
      'a failed sync records languageSyncFailure and leaves saveStatus alone '
      '— the language itself was already applied locally and is not rolled '
      'back (a worker/manager gets 403 on PATCH /account-settings, and the '
      'offline case behaves the same)',
      build: () {
        when(() => sessionManager.userType).thenReturn(UserType.worker);
        when(() => updateAccountSettings(any(), any())).thenAnswer(
          (_) => TaskEither.left(
            const UnauthorizedRoleFailure(message: 'Forbidden'),
          ),
        );
        return build();
      },
      act: (bloc) =>
          bloc.add(const AccountSettingsLanguageSynced(PreferredLanguage.ar)),
      expect: () => [
        isA<AccountSettingsState>()
            .having((s) => s.saveStatus, 'saveStatus', RequestStatus.initial)
            .having(
              (s) => s.languageSyncFailure?.message,
              'languageSyncFailure',
              'Forbidden',
            ),
      ],
      verify: (_) => verifyNever(() => sessionManager.update(any())),
    );

    blocTest<AccountSettingsBloc, AccountSettingsState>(
      'sends the requested language, not the session snapshot',
      build: () {
        when(
          () => sessionManager.userType,
        ).thenReturn(UserType.organizationProvider);
        when(
          () => updateAccountSettings(any(), any()),
        ).thenAnswer((_) => TaskEither.right(_refreshedSettings));
        return build();
      },
      act: (bloc) =>
          bloc.add(const AccountSettingsLanguageSynced(PreferredLanguage.ar)),
      verify: (_) => verify(
        () => updateAccountSettings(
          const UpdateAccountSettingsParams(
            preferredLanguage: PreferredLanguage.ar,
          ),
          UserType.organizationProvider,
        ),
      ).called(1),
    );
  });

  blocTest<AccountSettingsBloc, AccountSettingsState>(
    'a name-only save does not carry a language, so it cannot change the app '
    'language (regression: onSuccess used to re-apply the *server* '
    'preferredLanguage after every save, so renaming yourself flipped the UI)',
    build: () {
      when(
        () => sessionManager.userType,
      ).thenReturn(UserType.organizationProvider);
      when(
        () => updateAccountSettings(any(), any()),
      ).thenAnswer((_) => TaskEither.right(_refreshedSettings));
      return build();
    },
    act: (bloc) => bloc.add(
      const AccountSettingsUpdated(
        UpdateAccountSettingsParams(name: 'Layla Al Yamani'),
      ),
    ),
    verify: (_) => verify(
      () => updateAccountSettings(
        const UpdateAccountSettingsParams(name: 'Layla Al Yamani'),
        UserType.organizationProvider,
      ),
    ).called(1),
  );
}
