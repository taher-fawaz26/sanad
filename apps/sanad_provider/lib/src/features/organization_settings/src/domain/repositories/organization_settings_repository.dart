import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/update_service_provider_settings_params.dart';

/// Reads/writes the organization's business profile — the single source of
/// truth for the Organization Settings feature.
abstract interface class OrganizationSettingsRepository {
  TaskEither<Failure, OrganizationProfileEntity> getOrganizationSettings();

  /// The cached business profile for the signed-in user, or `null` if
  /// nothing is cached yet (or no session is active). Pure local read — no
  /// network, no [Failure], resolves near-instantly.
  Future<OrganizationProfileEntity?> getCachedOrganizationSettings();

  /// Write-through for a LOCAL merge that didn't itself hit `GET /settings`
  /// (e.g. a cover/logo upload, or a description/category/social-profile
  /// PATCH whose `204` response gets merged in-memory) — without this, the
  /// cache would keep serving the pre-edit value until the next full
  /// network refresh happens to occur.
  Future<void> cacheOrganizationSettings(
    OrganizationProfileEntity organization,
  );

  /// `PATCH service-provider/settings` — description/categories/social
  /// profiles. Returns `204 No Content` on the wire; callers must locally
  /// merge the fields they sent (or re-fetch [getOrganizationSettings]) to
  /// see the authoritative shape.
  TaskEither<Failure, Unit> updateServiceProviderSettings(
    UpdateServiceProviderSettingsParams params,
  );

  /// `GET service-provider/completion`.
  TaskEither<Failure, ProviderCompletionEntity> getCompletion();
}
