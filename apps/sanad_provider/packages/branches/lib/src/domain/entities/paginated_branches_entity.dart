import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:equatable/equatable.dart';

class BranchPaginationMeta extends Equatable {
  const BranchPaginationMeta({
    required this.totalItems,
    required this.itemCount,
    required this.itemsPerPage,
    required this.totalPages,
    required this.currentPage,
  });

  final int totalItems;
  final int itemCount;
  final int itemsPerPage;
  final int totalPages;
  final int currentPage;

  bool get hasMore => currentPage < totalPages;

  @override
  List<Object?> get props => [
    totalItems,
    itemCount,
    itemsPerPage,
    totalPages,
    currentPage,
  ];
}

class PaginatedBranchesEntity extends Equatable {
  const PaginatedBranchesEntity({
    required this.branches,
    required this.meta,
  });

  final List<BranchEntity> branches;
  final BranchPaginationMeta meta;

  @override
  List<Object?> get props => [branches, meta];
}
