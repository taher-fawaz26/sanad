import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/data/datasources/services_remote_data_source.dart';
import 'package:services/src/data/models/create_service_dto.dart';
import 'package:services/src/data/models/update_service_dto.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/service_analytics_entity.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/domain/repositories/services_repository.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  const ServicesRepositoryImpl(this._remoteDataSource);

  final ServicesRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, ServiceRecordEntity> createService({
    required String name,
    String? description,
    required String categoryId,
    required num price,
    bool? isActive,
    List<String>? mediaIds,
  }) => _remoteDataSource
      .createService(
        CreateServiceDto(
          name: name,
          description: description,
          categoryId: categoryId,
          price: price,
          isActive: isActive,
          mediaIds: mediaIds,
        ),
      )
      .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ServicesPagedResult<ServiceRecordEntity>> getServices({
    int page = 1,
    int limit = 10,
    String? search,
    String? categoryId,
    bool? isActive,
  }) => _remoteDataSource
      .getServices(
        page: page,
        limit: limit,
        search: search,
        categoryId: categoryId,
        isActive: isActive,
      )
      .map(
        (paged) => ServicesPagedResult(
          items: paged.items.map((dto) => dto.toEntity()).toList(),
          meta: paged.meta,
        ),
      );

  @override
  TaskEither<Failure, ServiceRecordEntity> getService(String id) =>
      _remoteDataSource.getService(id).map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ServiceRecordEntity> updateService({
    required String id,
    String? name,
    String? description,
    String? categoryId,
    num? price,
    bool? isActive,
    List<String>? mediaIds,
  }) => _remoteDataSource
      .updateService(
        id,
        UpdateServiceDto(
          name: name,
          description: description,
          categoryId: categoryId,
          price: price,
          isActive: isActive,
          mediaIds: mediaIds,
        ),
      )
      .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, Unit> deleteService(String id) =>
      _remoteDataSource.deleteService(id);

  @override
  TaskEither<Failure, ServiceRecordEntity> updateServiceStatus({
    required String id,
    required bool isActive,
  }) => _remoteDataSource
      .updateServiceStatus(id, isActive)
      .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ServiceAnalyticsEntity> getServiceAnalytics() =>
      _remoteDataSource.getServiceAnalytics();
}
