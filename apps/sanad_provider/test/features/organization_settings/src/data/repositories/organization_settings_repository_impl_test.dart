// ignore_for_file: prefer_const_constructors, unnecessary_lambdas

import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/legal_data_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/organization_settings_cache_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/organization_settings_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/business_profile_me_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/legal_data_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/me_settings_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/repositories/organization_settings_repository_impl.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/business_profile_status.dart';

class _MockRemote extends Mock
    implements OrganizationSettingsRemoteDataSource {}

class _MockLegalDataRemote extends Mock implements LegalDataRemoteDataSource {}

class _MockCache extends Mock implements OrganizationSettingsCacheDataSource {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockSessionManager extends Mock implements SessionManager {}

/// A legal-data envelope with both slot fields null — the repository only
/// reads `personalLegalData` and `tradeLicenseLegalData` off the response,
/// both of which are already nullable in the DTO. A `Fake` with dynamic
/// `noSuchMethod` returning null exercises the null path without pulling in
/// the full nested-DTO tree.
class _FakeLegalDataResponse extends Fake implements LegalDataResponse {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeUser extends Fake implements UserEntity {
  @override
  String get id => 'user-1';
}

class _FakeMeSettings extends Fake implements MeSettingsResponse {}

void main() {
  late _MockRemote remote;
  late _MockLegalDataRemote legalDataRemote;
  late _MockCache cache;
  late _MockConnectivity connectivity;
  late NetworkGuard networkGuard;
  late _MockSessionManager session;

  final businessProfile = BusinessProfileMeResponse(
    id: 'org-1',
    categories: const [],
    status: BusinessProfileStatus.inReview,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  setUpAll(() {
    registerFallbackValue(_FakeMeSettings());
  });

  setUp(() {
    remote = _MockRemote();
    legalDataRemote = _MockLegalDataRemote();
    cache = _MockCache();
    connectivity = _MockConnectivity();
    // Real `NetworkGuard` with a mocked connectivity that reports "online"
    // — simpler than mocking `execute`'s generic signature via mocktail.
    networkGuard = NetworkGuard(connectivity);
    session = _MockSessionManager();

    when(() => connectivity.isConnected()).thenAnswer((_) async => true);
    when(() => session.user).thenReturn(_FakeUser());

    when(() => remote.getOrganizationSettings()).thenAnswer(
      (_) => TaskEither.right(
        MeSettingsResponse(businessProfile: businessProfile),
      ),
    );

    when(() => cache.writeProfile(any(), any())).thenAnswer((_) async {});
  });

  OrganizationSettingsRepositoryImpl build() =>
      OrganizationSettingsRepositoryImpl(
        remote,
        legalDataRemote,
        networkGuard,
        cache,
        session,
      );

  group('getOrganizationSettings — legal-data gating (RBAC Phase 7K)', () {
    test(
      'a non-owner (worker/manager) does NOT trigger '
      'GET /service-provider/legal-data — the exact reported bug this '
      'phase closes. The inner _fetchLegalDataOrNull short-circuits to '
      'null instead of firing the owner-only request.',
      () async {
        when(() => session.isProvider).thenReturn(false);

        final result = await build().getOrganizationSettings().run();

        expect(result.isRight(), isTrue);
        verifyNever(() => legalDataRemote.fetchLegalData());
        verify(() => remote.getOrganizationSettings()).called(1);
      },
    );

    test(
      'an owner (isProvider=true) still triggers legal-data — the '
      'compliance-documents section depends on it',
      () async {
        when(() => session.isProvider).thenReturn(true);
        when(
          () => legalDataRemote.fetchLegalData(),
        ).thenAnswer((_) => TaskEither.right(_FakeLegalDataResponse()));

        final result = await build().getOrganizationSettings().run();

        expect(result.isRight(), isTrue);
        verify(() => legalDataRemote.fetchLegalData()).called(1);
      },
    );
  });
}
