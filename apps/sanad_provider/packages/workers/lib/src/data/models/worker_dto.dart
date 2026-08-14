import 'package:core/core.dart';
import 'package:workers/src/domain/entities/worker_assigned_branch.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';

class WorkerDto extends WorkerEntity implements EntityConverter<WorkerEntity> {
  const WorkerDto({
    required super.id,
    required super.fullName,
    required super.role,
    required super.initials,
    super.status,
    super.phone,
    super.email,
    super.jobTitle,
    super.profilePicUrl,
    super.assignedBranches,
  });

  factory WorkerDto.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final profilePic = json['profilePic'] as Map<String, dynamic>?;
    final branches = (json['assignedBranches'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (b) => WorkerAssignedBranch(
            id: b['id'] as String? ?? '',
            branchName: b['branchName'] as String? ?? '',
            role: b['role'] as String? ?? 'worker',
          ),
        )
        .toList();

    return WorkerDto(
      id: json['id'] as String,
      fullName: name,
      role: json['type'] as String? ?? 'worker',
      initials: _initials(name),
      status: WorkerStatus.fromString(json['status'] as String?),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      jobTitle: json['jobTitle'] as String?,
      profilePicUrl: profilePic?['url'] as String?,
      assignedBranches: branches,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': fullName, 'type': role};

  @override
  WorkerEntity toEntity() => WorkerEntity(
    id: id,
    fullName: fullName,
    role: role,
    initials: initials,
    status: status,
    phone: phone,
    email: email,
    jobTitle: jobTitle,
    profilePicUrl: profilePicUrl,
    assignedBranches: assignedBranches,
  );

  static String _initials(String name) => initialsOf(name) ?? '';
}
