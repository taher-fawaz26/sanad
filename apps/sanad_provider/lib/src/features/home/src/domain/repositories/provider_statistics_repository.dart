import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';

/// Reads the provider dashboard statistic cards —
/// `service-provider/statistics`.
abstract interface class ProviderStatisticsRepository {
  TaskEither<Failure, List<ProviderStatisticEntity>> getStatistics();
}
