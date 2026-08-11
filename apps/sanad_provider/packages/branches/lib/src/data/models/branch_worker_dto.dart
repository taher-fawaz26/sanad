import 'package:branches/src/data/models/person_initials.dart';
import 'package:branches/src/domain/entities/branch_worker_entity.dart';
import 'package:branches/src/domain/entities/branch_worker_type.dart';
import 'package:branches/src/domain/entities/worker_status.dart';

class BranchWorkerDto {
  const BranchWorkerDto({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
  });

  factory BranchWorkerDto.fromJson(Map<String, dynamic> json) =>
      BranchWorkerDto(
        id: json['id'] as String,
        name: json['name'] as String,
        type: BranchWorkerType.fromApiString(json['type'] as String?),
        status: WorkerStatus.fromApiString(json['status'] as String?),
      );

  final String id;
  final String name;
  final BranchWorkerType type;
  final WorkerStatus status;

  BranchWorkerEntity toDomain() => BranchWorkerEntity(
    id: id,
    fullName: name,
    initials: personInitials(name),
    type: type,
    status: status,
  );
}
