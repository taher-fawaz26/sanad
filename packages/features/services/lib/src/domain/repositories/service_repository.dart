import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/service_entity.dart';

abstract interface class ServiceRepository {
  TaskEither<Failure, List<ServiceEntity>> getServices();
}
