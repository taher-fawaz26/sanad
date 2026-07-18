import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/paginated_branches_entity.dart';
import 'package:equatable/equatable.dart';

class PaginatedManagersEntity extends Equatable {
  const PaginatedManagersEntity({
    required this.managers,
    required this.meta,
  });

  final List<BranchManagerEntity> managers;
  final BranchPaginationMeta meta;

  @override
  List<Object?> get props => [managers, meta];
}
