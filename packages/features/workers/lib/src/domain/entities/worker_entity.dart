import 'package:equatable/equatable.dart';
import 'package:workers/src/domain/entities/worker_assigned_branch.dart';
import 'package:workers/src/domain/entities/worker_status.dart';

class WorkerEntity extends Equatable {
  const WorkerEntity({
    required this.id,
    required this.fullName,
    required this.role,
    required this.initials,
    this.status = WorkerStatus.inactive,
    this.phone,
    this.email,
    this.jobTitle,
    this.profilePicUrl,
    this.assignedBranches = const [],
  });

  final String id;
  final String fullName;

  /// API worker type (`worker`, `manager`).
  final String role;
  final String initials;
  final WorkerStatus status;
  final String? phone;
  final String? email;
  final String? jobTitle;

  /// Public URL of the worker's profile picture, when set.
  final String? profilePicUrl;

  /// Branches this worker is assigned to.
  final List<WorkerAssignedBranch> assignedBranches;

  @override
  List<Object?> get props => [
    id,
    fullName,
    role,
    initials,
    status,
    phone,
    email,
    jobTitle,
    profilePicUrl,
    assignedBranches,
  ];
}
