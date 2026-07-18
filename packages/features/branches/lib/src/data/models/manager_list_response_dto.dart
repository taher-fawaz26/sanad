import 'package:branches/src/data/models/branch_manager_dto.dart';
import 'package:branches/src/domain/entities/paginated_branches_entity.dart';
import 'package:branches/src/domain/entities/paginated_managers_entity.dart';

class ManagerListResponseDto {
  const ManagerListResponseDto({required this.managers, required this.meta});

  factory ManagerListResponseDto.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>)
        .map((e) => BranchManagerDto.fromJson(e as Map<String, dynamic>))
        .toList();

    final metaJson = json['meta'] as Map<String, dynamic>;
    final meta = BranchPaginationMeta(
      totalItems: metaJson['totalItems'] as int? ?? 0,
      itemCount: metaJson['itemCount'] as int? ?? 0,
      itemsPerPage: metaJson['itemsPerPage'] as int? ?? 10,
      totalPages: metaJson['totalPages'] as int? ?? 1,
      currentPage: metaJson['currentPage'] as int? ?? 1,
    );

    return ManagerListResponseDto(managers: data, meta: meta);
  }

  final List<BranchManagerDto> managers;
  final BranchPaginationMeta meta;

  PaginatedManagersEntity toDomain() => PaginatedManagersEntity(
    managers: managers.map((m) => m.toDomain()).toList(),
    meta: meta,
  );
}
