import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:organization_settings/src/domain/entities/organization_settings_entity.dart';

/// Reads the organization's full settings profile — the single source of
/// truth for the Organization Settings feature.
abstract interface class OrganizationSettingsRepository {
  TaskEither<Failure, OrganizationSettingsEntity> getOrganizationSettings();
}
