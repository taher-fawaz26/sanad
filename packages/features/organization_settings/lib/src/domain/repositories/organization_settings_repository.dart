import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:organization_settings/src/domain/usecases/update_service_provider_settings_params.dart';

/// Reads/writes the organization's business profile — the single source of
/// truth for the Organization Settings feature.
abstract interface class OrganizationSettingsRepository {
  TaskEither<Failure, OrganizationProfileEntity> getOrganizationSettings();

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
