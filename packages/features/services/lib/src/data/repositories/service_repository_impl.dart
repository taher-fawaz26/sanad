import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/data/datasources/service_remote_data_source.dart';
import 'package:services/src/domain/entities/service_entity.dart';
import 'package:services/src/domain/repositories/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  const ServiceRepositoryImpl(this._remoteDataSource);

  final ServiceRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, List<ServiceEntity>> getServices() =>
      _remoteDataSource.getServices().map(
            (dtos) => dtos.map((dto) => dto.toEntity()).toList(),
          );
}
