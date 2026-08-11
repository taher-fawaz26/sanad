import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_overview_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/provider_overview_repository.dart';

class GetProviderOverviewUseCase
    implements UseCase<ProviderOverviewEntity, NoParams> {
  const GetProviderOverviewUseCase(this._repository);

  final ProviderOverviewRepository _repository;

  @override
  TaskEither<Failure, ProviderOverviewEntity> call(NoParams params) =>
      _repository.getOverview();
}
