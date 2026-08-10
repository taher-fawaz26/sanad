import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/domain/repositories/services_repository.dart';

class CreateServiceParams extends Equatable {
  const CreateServiceParams({
    required this.name,
    this.description,
    required this.categoryId,
    required this.price,
    this.isActive,
    this.mediaIds,
  });

  final String name;
  final String? description;
  final String categoryId;
  final num price;
  final bool? isActive;
  final List<String>? mediaIds;

  @override
  List<Object?> get props => [
    name,
    description,
    categoryId,
    price,
    isActive,
    mediaIds,
  ];
}

class CreateServiceUseCase
    implements UseCase<ServiceRecordEntity, CreateServiceParams> {
  const CreateServiceUseCase(this._repository);

  final ServicesRepository _repository;

  @override
  TaskEither<Failure, ServiceRecordEntity> call(CreateServiceParams params) =>
      _repository.createService(
        name: params.name,
        description: params.description,
        categoryId: params.categoryId,
        price: params.price,
        isActive: params.isActive,
        mediaIds: params.mediaIds,
      );
}
