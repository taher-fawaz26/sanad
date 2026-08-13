import 'package:account_settings/src/data/datasources/account_settings_remote_datasource.dart';
import 'package:account_settings/src/data/endpoints/account_settings_api_paths.dart';
import 'package:account_settings/src/data/models/account_settings_response.dart';
import 'package:account_settings/src/domain/enums/preferred_language.dart';
import 'package:auth/auth.dart' show UserType;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';

class _MockBaseApiClient extends Mock implements BaseApiClient {}

void main() {
  late _MockBaseApiClient apiClient;
  late AccountSettingsRemoteDataSourceImpl dataSource;

  // Verbatim `GET /service-provider/profile` envelope from the live dev API
  // for an organizationProvider account.
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
    dataSource = AccountSettingsRemoteDataSourceImpl(apiClient);
  });

  test(
    'getAccountProfile hits service-provider/profile for '
    'organizationProvider and extracts the nested accountSettings object',
    () async {
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

      final result = await dataSource
          .getAccountProfile(UserType.organizationProvider)
          .run();

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('expected a right, got $failure'),
        (response) {
          expect(response.id, 'e3521ee5-3f43-4af1-819b-8c0f1f164a5f');
          expect(response.name, 'Layla Al Mansoori');
          expect(response.email, 'seed-company-provider-1@sanad.test');
          expect(response.phone, '+971501234567');
          expect(response.preferredLanguage, PreferredLanguage.en);
        },
      );

      verify(
        () => apiClient.request<AccountSettingsResponse>(
          path: AccountSettingsApiPaths.serviceProviderProfile,
          method: RequestMethod.get,
          body: any<dynamic>(named: 'body'),
          parser: any(named: 'parser'),
          query: any(named: 'query'),
        ),
      ).called(1);
    },
  );
}
