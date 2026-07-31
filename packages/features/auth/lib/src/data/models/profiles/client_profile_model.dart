import 'package:auth/src/domain/entities/auth_profile_entity.dart';

/// Data model for [ClientProfileEntity] — inherits fields, adds JSON I/O.
class ClientProfileModel extends ClientProfileEntity {
  const ClientProfileModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.emiratesId,
  });

  factory ClientProfileModel.fromJson(Map<String, dynamic> json) {
    return ClientProfileModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      emiratesId: json['emiratesId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'emiratesId': emiratesId,
  };
}
