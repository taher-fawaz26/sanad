// Integration-style test: exercises the REAL chain — GetCurrentUserUseCase
// (auth) → AccountSettingsRemoteDataSource → AccountSettingsRepository →
// RefreshAccountProfileUseCase — wired together exactly as DI does, with
// only the HTTP boundary (BaseApiClient) and connectivity mocked. This is
// the one link Phase 1's other tests didn't cover in combination: each of
// them mocked the *next* layer up, so a wiring mistake between layers
// (wrong path, wrong field extraction, wrong composition) could hide.
//
// Regression fixture: the verbatim `GET /me` + `GET /service-provider/profile`
// response pair reported against a live organizationProvider account.
import 'package:account_settings/src/data/datasources/account_settings_remote_datasource.dart';
import 'package:account_settings/src/data/models/account_settings_response.dart';
import 'package:account_settings/src/data/repositories/account_settings_repository_impl.dart';
import 'package:account_settings/src/domain/enums/preferred_language.dart';
import 'package:account_settings/src/domain/usecases/refresh_account_profile_usecase.dart';
import 'package:auth/src/data/datasources/auth_remote_datasource.dart';
import 'package:auth/src/data/datasources/google_auth_datasource.dart';
import 'package:auth/src/data/repositories/auth_repository_impl.dart';
import 'package:auth/src/domain/entities/auth_identity_entity.dart';
import 'package:auth/src/domain/usecases/get_current_user_usecase.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';

class _MockBaseApiClient extends Mock implements BaseApiClient {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

class _MockGoogleAuthDataSource extends Mock implements GoogleAuthDataSource {}

void main() {
  late _MockBaseApiClient apiClient;
  late _MockConnectivityService connectivity;
  late RefreshAccountProfileUseCase useCase;

  final meEnvelope = <String, dynamic>{
    'id': 'e3521ee5-3f43-4af1-819b-8c0f1f164a5f',
    'email': 'seed-company-provider-1@sanad.test',
    'userType': 'organizationProvider',
    'name': 'Layla Al Mansoori',
    'isActive': true,
  };

  final profileEnvelope = <String, dynamic>{
    'id': 'e3521ee5-3f43-4af1-819b-8c0f1f164a5f',
    'userType': 'organizationProvider',
    'status': 'ACTIVE',
    'accountSettings': {
      'id': 'e3521ee5-3f43-4af1-819b-8c0f1f164a5f',
      'name': 'Layla Al Mansoori',
      'email': 'seed-company-provider-1@sanad.test',
      'phone': '+971501234567',
      'preferredLanguage': 'en',
    },
  };

  setUpAll(() {
    registerFallbackValue(RequestMethod.get);
  });

  setUp(() {
    apiClient = _MockBaseApiClient();
    connectivity = _MockConnectivityService();
    when(() => connectivity.isConnected()).thenAnswer((_) async => true);

    // `apiClient.request<T>` is generic — mocktail stubs by exact type
    // argument, so `GET /me` (T = AuthIdentity) and
    // `GET /service-provider/profile` (T = AccountSettingsResponse) need
    // separate stubs even though they share the same mock instance.
    when(
      () => apiClient.request<AuthIdentity>(
        path: any(named: 'path'),
        method: any(named: 'method'),
        body: any<dynamic>(named: 'body'),
        parser: any(named: 'parser'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((invocation) {
      final parser =
          invocation.namedArguments[#parser] as AuthIdentity Function(dynamic);
      return TaskEither.right(parser(meEnvelope));
    });
    when(
      () => apiClient.request<AccountSettingsResponse>(
        path: any(named: 'path'),
        method: any(named: 'method'),
        body: any<dynamic>(named: 'body'),
        parser: any(named: 'parser'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((invocation) {
      final parser =
          invocation.namedArguments[#parser]
              as AccountSettingsResponse Function(dynamic);
      return TaskEither.right(parser(profileEnvelope));
    });

    final authRemote = AuthRemoteDataSourceImpl(apiClient);
    final authRepository = AuthRepositoryImpl(
      authRemote,
      _MockGoogleAuthDataSource(),
    );
    final getCurrentUser = GetCurrentUserUseCase(authRepository);

    final accountRemote = AccountSettingsRemoteDataSourceImpl(apiClient);
    final accountRepository = AccountSettingsRepositoryImpl(
      accountRemote,
      NetworkGuard(connectivity),
    );

    useCase = RefreshAccountProfileUseCase(getCurrentUser, accountRepository);
  });

  test(
    'GET /me + GET /service-provider/profile resolve to the correct '
    'AccountSettingsEntity for an organizationProvider account',
    () async {
      final result = await useCase(const NoParams()).run();

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('expected a right, got $failure'),
        (settings) {
          expect(settings.name, 'Layla Al Mansoori');
          expect(settings.email, 'seed-company-provider-1@sanad.test');
          expect(settings.phone, '+971501234567');
          expect(settings.preferredLanguage, PreferredLanguage.en);
        },
      );
    },
  );
}
