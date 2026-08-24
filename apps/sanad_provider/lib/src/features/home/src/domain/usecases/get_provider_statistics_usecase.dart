import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';
import 'package:sanad_provider/src/features/home/src/domain/repositories/provider_statistics_repository.dart';

class GetProviderStatisticsUseCase
    implements UseCase<List<ProviderStatisticEntity>, NoParams> {
  const GetProviderStatisticsUseCase(this._repository);

  final ProviderStatisticsRepository _repository;

  @override
  TaskEither<Failure, List<ProviderStatisticEntity>> call(NoParams params) =>
      _repository.getStatistics();
}
