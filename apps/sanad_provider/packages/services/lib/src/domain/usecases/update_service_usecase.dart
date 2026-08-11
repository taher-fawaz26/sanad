import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/domain/repositories/services_repository.dart';

class UpdateServiceParams extends Equatable {
  const UpdateServiceParams({
    required this.id,
    this.name,
    this.description,
    this.categoryId,
    this.price,
    this.isActive,
    this.mediaIds,
  });

  final String id;
  final String? name;
  final String? description;
  final String? categoryId;
  final num? price;
  final bool? isActive;
  final List<String>? mediaIds;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    categoryId,
    price,
    isActive,
    mediaIds,
  ];
}

class UpdateServiceUseCase
    implements UseCase<ServiceRecordEntity, UpdateServiceParams> {
  const UpdateServiceUseCase(this._repository);

  final ServicesRepository _repository;

  @override
  TaskEither<Failure, ServiceRecordEntity> call(UpdateServiceParams params) =>
      _repository.updateService(
        id: params.id,
        name: params.name,
        description: params.description,
        categoryId: params.categoryId,
        price: params.price,
        isActive: params.isActive,
        mediaIds: params.mediaIds,
      );
}
