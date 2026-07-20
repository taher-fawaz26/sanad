import 'package:equatable/equatable.dart';
import 'package:workers/src/domain/entities/worker_status.dart';

class WorkerEntity extends Equatable {
  const WorkerEntity({
    required this.id,
    required this.fullName,
    required this.role,
    required this.initials,
    this.status = WorkerStatus.pending,
    this.phone,
    this.email,
    this.branches,
  });

  final String id;
  final String fullName;
  final String role;
  final String initials;
  final WorkerStatus status;
  final String? phone;
  final String? email;
  final String? branches;

  @override
  List<Object?> get props => [
    id,
    fullName,
    role,
    initials,
    status,
    phone,
    email,
    branches,
  ];
}
