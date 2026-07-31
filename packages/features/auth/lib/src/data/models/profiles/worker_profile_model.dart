import 'package:auth/src/domain/entities/auth_profile_entity.dart';
import 'package:auth/src/domain/entities/worker_status.dart';
import 'package:auth/src/domain/enums/worker_type.dart';

/// Data model for [WorkerProfileEntity].
class WorkerProfileModel extends WorkerProfileEntity {
  const WorkerProfileModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
    required super.jobTitle,
    required super.type,
    required super.status,
  });

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    return WorkerProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      jobTitle: json['jobTitle'] as String,
      type: json['type'] is String
          ? WorkerType.fromString(json['type'] as String)
          : WorkerType.worker,
      status: json['status'] is String
          ? WorkerStatus.fromString(json['status'] as String)
          : WorkerStatus.active,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phoneNumber': phoneNumber,
    'jobTitle': jobTitle,
    'type': type.value,
    'status': status.value,
  };
}
