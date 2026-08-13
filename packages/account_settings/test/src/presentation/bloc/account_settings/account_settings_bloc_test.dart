import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/enums/preferred_language.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:account_settings/src/domain/usecases/refresh_account_profile_usecase.dart';
import 'package:account_settings/src/domain/usecases/update_account_settings_usecase.dart';
import 'package:account_settings/src/presentation/bloc/account_settings/account_settings_bloc.dart';
import 'package:auth/auth.dart'
    show AuthAccountSettingsEntity, AuthSessionEntity, SessionManager;
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
      when(() => updateAccountSettings(any())).thenAnswer(
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
      when(() => updateAccountSettings(any())).thenAnswer(
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
}
