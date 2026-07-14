import 'package:core/core.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';

class WorkerDto extends WorkerEntity implements EntityConverter<WorkerEntity> {
  const WorkerDto({
    required super.id,
    required super.fullName,
    required super.role,
    required super.initials,
  });

  factory WorkerDto.fromJson(Map<String, dynamic> json) => WorkerDto(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        role: json['role'] as String,
        initials: json['initials'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'fullName': fullName,
        'role': role,
        'initials': initials,
      };

  @override
  WorkerEntity toEntity() => WorkerEntity(
        id: id,
        fullName: fullName,
        role: role,
        initials: initials,
      );
}
