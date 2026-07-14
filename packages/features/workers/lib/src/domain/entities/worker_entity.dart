import 'package:equatable/equatable.dart';

class WorkerEntity extends Equatable {
  const WorkerEntity({
    required this.id,
    required this.fullName,
    required this.role,
    required this.initials,
  });

  final String id;
  final String fullName;
  final String role;
  final String initials;

  @override
  List<Object?> get props => [id, fullName, role, initials];
}
