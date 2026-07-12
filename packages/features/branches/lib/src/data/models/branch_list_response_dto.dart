import 'package:branches/src/data/models/branch_dto.dart';
import 'package:branches/src/domain/entities/paginated_branches_entity.dart';

/// Parses the `/provider/branches` paginated response.
///
/// The API uses a non-standard envelope:
/// `{ "data": [...], "meta": { "totalItems", "itemCount", "itemsPerPage",
/// "totalPages", "currentPage" } }` — different from the generic
/// [PaginatedResponse] in `packages/network` which expects `items/total/page`.
class BranchListResponseDto {
  const BranchListResponseDto({required this.branches, required this.meta});

  factory BranchListResponseDto.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>)
        .map((e) => BranchDto.fromJson(e as Map<String, dynamic>))
        .toList();

    final metaJson = json['meta'] as Map<String, dynamic>;
    final meta = BranchPaginationMeta(
      totalItems: metaJson['totalItems'] as int? ?? 0,
      itemCount: metaJson['itemCount'] as int? ?? 0,
      itemsPerPage: metaJson['itemsPerPage'] as int? ?? 10,
      totalPages: metaJson['totalPages'] as int? ?? 1,
      currentPage: metaJson['currentPage'] as int? ?? 1,
    );

    return BranchListResponseDto(branches: data, meta: meta);
  }

  final List<BranchDto> branches;
  final BranchPaginationMeta meta;

  PaginatedBranchesEntity toEntity() => PaginatedBranchesEntity(
        branches: branches.map((b) => b.toEntity()).toList(),
        meta: meta,
      );
}
