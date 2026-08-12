import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/data/datasources/provider_services_remote_data_source.dart';
import 'package:services/src/data/models/create_provider_service_dto.dart';
import 'package:services/src/data/models/update_provider_service_dto.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_overview_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';

class ProviderServicesRepositoryImpl implements ProviderServicesRepository {
  const ProviderServicesRepositoryImpl(this._remoteDataSource);

  final ProviderServicesRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, ServicesPagedResult<ProviderServiceEntity>>
  listProviderServices({
    int page = 1,
    int limit = 10,
    String? search,
    ProviderServiceStatus? status,
  }) => _remoteDataSource
      .listProviderServices(
        page: page,
        limit: limit,
        search: search,
        status: status,
      )
      .map(
        (paged) => ServicesPagedResult(
          items: paged.items.map((dto) => dto.toEntity()).toList(),
          meta: paged.meta,
        ),
      );

  @override
  TaskEither<Failure, ProviderServiceEntity> getProviderService(String id) =>
      _remoteDataSource.getProviderService(id).map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ProviderServiceEntity> createProviderService({
    required String serviceId,
    required String description,
    required List<String> imageIds,
  }) => _remoteDataSource
      .createProviderService(
        CreateProviderServiceDto(
          serviceId: serviceId,
          description: description,
          imageIds: imageIds,
        ),
      )
      .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ProviderServiceEntity> updateProviderService({
    required String id,
    required String description,
  }) => _remoteDataSource
      .updateProviderService(
        id,
        UpdateProviderServiceDto(description: description),
      )
      .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, Unit> deleteProviderService(String id) =>
      _remoteDataSource.deleteProviderService(id);

  @override
  TaskEither<Failure, ProviderServiceEntity> updateProviderServiceStatus({
    required String id,
    required ProviderServiceStatus status,
  }) => _remoteDataSource
      .updateProviderServiceStatus(id, status)
      .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ProviderServiceOverviewEntity> getOverview() =>
      _remoteDataSource.getOverview();

  @override
  TaskEither<Failure, ProviderServiceOverviewEntity> getOverviewFor(
    String id,
  ) => _remoteDataSource.getOverviewFor(id);

  @override
  TaskEither<Failure, ProviderServiceEntity> addImage({
    required String id,
    required String mediaId,
  }) => _remoteDataSource
      .addImage(id, mediaId)
      .flatMap((_) => _remoteDataSource.getProviderService(id))
      .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, Unit> deleteImage({
    required String id,
    required String imageId,
  }) => _remoteDataSource.deleteImage(id, imageId);

  @override
  TaskEither<Failure, ProviderServiceEntity> setPrimaryImage({
    required String id,
    required String imageId,
  }) => _remoteDataSource
      .setPrimaryImage(id, imageId)
      .map((dto) => dto.toEntity());
}
