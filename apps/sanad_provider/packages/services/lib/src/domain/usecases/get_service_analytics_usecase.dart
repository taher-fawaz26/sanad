import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/service_analytics_entity.dart';
import 'package:services/src/domain/repositories/services_repository.dart';

class GetServiceAnalyticsUseCase
    implements UseCase<ServiceAnalyticsEntity, NoParams> {
  const GetServiceAnalyticsUseCase(this._repository);

  final ServicesRepository _repository;

  @override
  TaskEither<Failure, ServiceAnalyticsEntity> call(NoParams params) =>
      _repository.getServiceAnalytics();
}
