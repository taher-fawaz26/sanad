import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:services/src/data/endpoints/service_api_paths.dart';
import 'package:services/src/data/models/service_dto.dart';

abstract interface class ServiceRemoteDataSource {
  TaskEither<Failure, List<ServiceDto>> getServices();
}

class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  const ServiceRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, List<ServiceDto>> getServices() =>
      _apiClient.request<List<ServiceDto>>(
        path: ServiceApiPaths.services,
        method: RequestMethod.get,
        parser: _parseGroupedServices,
      );

  static List<ServiceDto> _parseGroupedServices(dynamic raw) {
    final json = raw as Map<String, dynamic>;
    final groups = json['data'] as List<dynamic>;
    final services = <ServiceDto>[];
    for (final group in groups) {
      final entry = group as Map<String, dynamic>;
      final categoryJson = entry['category'] as Map<String, dynamic>;
      final categoryName = categoryJson['name'] as String;
      final items = entry['services'] as List<dynamic>;
      for (final item in items) {
        services.add(
          ServiceDto.fromJsonWithCategory(
            item as Map<String, dynamic>,
            categoryName,
          ),
        );
      }
    }
    return services;
  }
}
