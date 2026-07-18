import 'package:branches/src/domain/entities/branch_worker_type.dart';
import 'package:branches/src/domain/entities/worker_status.dart';
import 'package:equatable/equatable.dart';

class BranchWorkerEntity extends Equatable {
  const BranchWorkerEntity({
    required this.id,
    required this.fullName,
    required this.initials,
    required this.type,
    required this.status,
  });

  final String id;
  final String fullName;
  final String initials;
  final BranchWorkerType type;
  final WorkerStatus status;

  bool get isManager => type == BranchWorkerType.manager;
  bool get isActive => status == WorkerStatus.active;

  @override
  List<Object?> get props => [id, fullName, initials, type, status];
}
