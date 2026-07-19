import 'package:core/core.dart';
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
    super.branches,
  });

  factory WorkerDto.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return WorkerDto(
      id: json['id'] as String,
      fullName: name,
      role: json['type'] as String? ?? 'worker',
      initials: _initials(name),
      status: WorkerStatus.fromString(json['status'] as String?),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      branches: json['branches'] as String?,
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
    branches: branches,
  );

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    return words
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
  }
}
