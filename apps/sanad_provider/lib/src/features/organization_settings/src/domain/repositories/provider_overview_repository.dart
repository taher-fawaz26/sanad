import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_overview_entity.dart';

/// Reads the provider KPI-hub summary counts — `service-provider/overview`.
abstract interface class ProviderOverviewRepository {
  TaskEither<Failure, ProviderOverviewEntity> getOverview();
}
