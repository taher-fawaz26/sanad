import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/service_analytics_entity.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';

/// CRUD + analytics for the provider's own services (`POST/GET/PATCH/DELETE
/// /services`, `/services/analytics`).
///
/// Named in the plural, and deliberately distinct from the pre-existing
/// singular `ServiceRepository` — that one backs an unrelated branch-service
/// -assignment catalog flow owned by the `branches` package and must not be
/// touched.
abstract interface class ServicesRepository {
  TaskEither<Failure, ServiceRecordEntity> createService({
    required String name,
    String? description,
    required String categoryId,
    required num price,
    bool? isActive,
    List<String>? mediaIds,
  });

  TaskEither<Failure, ServicesPagedResult<ServiceRecordEntity>> getServices({
    int page = 1,
    int limit = 10,
    String? search,
    String? categoryId,
    bool? isActive,
  });

  TaskEither<Failure, ServiceRecordEntity> getService(String id);

  TaskEither<Failure, ServiceRecordEntity> updateService({
    required String id,
    String? name,
    String? description,
    String? categoryId,
    num? price,
    bool? isActive,
    List<String>? mediaIds,
  });

  TaskEither<Failure, Unit> deleteService(String id);

  TaskEither<Failure, ServiceRecordEntity> updateServiceStatus({
    required String id,
    required bool isActive,
  });

  TaskEither<Failure, ServiceAnalyticsEntity> getServiceAnalytics();
}
