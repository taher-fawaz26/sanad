import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:services/src/data/endpoints/service_api_paths.dart';
import 'package:services/src/data/models/service_dto.dart';

abstract interface class ServiceRemoteDataSource {
  TaskEither<Failure, List<ServiceDto>> getServices();
}

/// Static services returned until the API is wired.
const _kStaticServices = <ServiceDto>[
  ServiceDto(id: 'svc-oil-change', name: 'Oil Change'),
  ServiceDto(id: 'svc-battery-replacement', name: 'Battery Replacement'),
  ServiceDto(id: 'svc-car-wash', name: 'Car Wash'),
  ServiceDto(id: 'svc-engine-repair', name: 'Engine Repair'),
  ServiceDto(id: 'svc-tire-rotation', name: 'Tire Rotation'),
  ServiceDto(id: 'svc-brake-pad-replacement', name: 'Brake Pad Replacement'),
  ServiceDto(
    id: 'svc-transmission-fluid-check',
    name: 'Transmission Fluid Check',
  ),
];

class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  const ServiceRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, List<ServiceDto>> getServices() =>
      TaskEither.right(_kStaticServices);

  // Future API integration:
  // _apiClient.request<List<ServiceDto>>(
  //   path: ServiceApiPaths.services,
  //   method: RequestMethod.get,
  //   parser: (data) => (data as List<dynamic>)
  //       .map((e) => ServiceDto.fromJson(e as Map<String, dynamic>))
  //       .toList(),
  // );
}
