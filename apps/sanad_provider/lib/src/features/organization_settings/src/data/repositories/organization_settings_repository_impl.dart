import 'dart:async';

import 'package:auth/auth.dart' show SessionManager;
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/legal_data_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/organization_settings_cache_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/organization_settings_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/business_profile_me_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/legal_data_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/me_settings_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/organization_settings_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/update_service_provider_settings_params.dart';

class OrganizationSettingsRepositoryImpl
    implements OrganizationSettingsRepository {
  const OrganizationSettingsRepositoryImpl(
    this._remote,
    this._legalDataRemote,
    this._networkGuard,
    this._cache,
    this._sessionManager,
  );

  final OrganizationSettingsRemoteDataSource _remote;
  final LegalDataRemoteDataSource _legalDataRemote;
  final NetworkGuard _networkGuard;
  final OrganizationSettingsCacheDataSource _cache;
  final SessionManager _sessionManager;

  @override
  TaskEither<Failure, OrganizationProfileEntity> getOrganizationSettings() =>
      _networkGuard.execute(
        action: _remote.getOrganizationSettings().flatMap(
          (response) => _fetchLegalDataOrNull().map((legalData) {
            _cacheProfile(response);
            return response.toEntity().copyWith(
              personalLegalData: legalData?.personalLegalData?.toEntity(),
              tradeLicenseLegalData: legalData?.tradeLicenseLegalData
                  ?.toEntity(),
            );
          }),
        ),
      );

  @override
  Future<OrganizationProfileEntity?> getCachedOrganizationSettings() async {
    final userId = _sessionManager.user?.id;
    if (userId == null) return null;
    final cached = await _cache.readProfile(userId);
    return cached?.toEntity();
  }

  @override
  Future<void> cacheOrganizationSettings(
    OrganizationProfileEntity organization,
  ) async {
    final userId = _sessionManager.user?.id;
    if (userId == null) return;
    await _cache.writeProfile(
      userId,
      MeSettingsResponse(
        businessProfile: BusinessProfileMeResponse.fromEntity(organization),
      ),
    );
  }

  /// Write-through, fire-and-forget — a cache-write failure (e.g. Hive
  /// unavailable) should never fail the read the user is actually waiting
  /// on. Caches the pre-merge business-profile DTO only; legal data is
  /// intentionally excluded (see [MeSettingsResponse] doc — it changes
  /// independently and the read path already tolerates it failing).
  void _cacheProfile(MeSettingsResponse response) {
    final userId = _sessionManager.user?.id;
    if (userId == null) return;
    unawaited(_cache.writeProfile(userId, response));
  }

  @override
  TaskEither<Failure, Unit> updateServiceProviderSettings(
    UpdateServiceProviderSettingsParams params,
  ) => _networkGuard.execute(
    action: _remote.updateServiceProviderSettings(params),
  );

  @override
  TaskEither<Failure, ProviderCompletionEntity> getCompletion() =>
      _networkGuard.execute(
        action: _remote.getCompletion().map((response) => response.toEntity()),
      );

  /// The Compliance Documents section is a nice-to-have overlay on top of
  /// the business profile, not the profile itself — if the dedicated
  /// legal-data endpoint fails (e.g. nothing submitted yet), the settings
  /// page should still render with those two fields simply absent rather
  /// than failing the whole page load.
  TaskEither<Failure, LegalDataResponse?> _fetchLegalDataOrNull() =>
      TaskEither(() async {
        final result = await _legalDataRemote.fetchLegalData().run();
        return result.match(
          (_) => const Right(null),
          Right.new,
        );
      });
}
