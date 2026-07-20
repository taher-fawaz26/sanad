import 'package:equatable/equatable.dart';

/// A branch a worker is assigned to, from `WorkerProfileResponseDto`'s
/// `assignedBranches` array.
class WorkerAssignedBranch extends Equatable {
  const WorkerAssignedBranch({
    required this.id,
    required this.branchName,
    required this.role,
  });

  final String id;
  final String branchName;

  /// How the worker is assigned to this branch: `manager` or `worker`.
  final String role;

  @override
  List<Object?> get props => [id, branchName, role];
}
