import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_overview_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';

abstract interface class ProviderServicesRepository {
  TaskEither<Failure, ServicesPagedResult<ProviderServiceEntity>>
  listProviderServices({
    int page = 1,
    int limit = 10,
    String? search,
    ProviderServiceStatus? status,
  });

  TaskEither<Failure, ProviderServiceEntity> getProviderService(String id);

  TaskEither<Failure, ProviderServiceEntity> createProviderService({
    required String serviceId,
    required String description,
    required List<String> imageIds,
  });

  TaskEither<Failure, ProviderServiceEntity> updateProviderService({
    required String id,
    required String description,
  });

  TaskEither<Failure, Unit> deleteProviderService(String id);

  TaskEither<Failure, ProviderServiceEntity> updateProviderServiceStatus({
    required String id,
    required ProviderServiceStatus status,
  });

  TaskEither<Failure, ProviderServiceOverviewEntity> getOverview();

  TaskEither<Failure, ProviderServiceEntity> addImage({
    required String id,
    required String mediaId,
  });

  TaskEither<Failure, ProviderServiceEntity> deleteImage({
    required String id,
    required String imageId,
  });

  TaskEither<Failure, ProviderServiceEntity> setPrimaryImage({
    required String id,
    required String imageId,
  });
}
