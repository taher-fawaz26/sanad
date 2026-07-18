import 'package:branches/src/data/models/person_initials.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';

class BranchManagerDto {
  const BranchManagerDto({required this.id, required this.name});

  factory BranchManagerDto.fromJson(Map<String, dynamic> json) =>
      BranchManagerDto(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;

  /// Raw `name` field from the API — mapped to [BranchManagerEntity.fullName].
  final String name;

  BranchManagerEntity toDomain() => BranchManagerEntity(
    id: id,
    fullName: name,
    initials: personInitials(name),
  );
}
