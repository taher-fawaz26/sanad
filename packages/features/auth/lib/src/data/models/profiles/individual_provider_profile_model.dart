import 'package:auth/src/domain/entities/auth_profile_entity.dart';

/// Data model for [IndividualProviderProfileEntity].
class IndividualProviderProfileModel extends IndividualProviderProfileEntity {
  const IndividualProviderProfileModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.emiratesId,
    required super.isReviewed,
  });

  factory IndividualProviderProfileModel.fromJson(Map<String, dynamic> json) {
    return IndividualProviderProfileModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      emiratesId: json['emiratesId'] as String,
      isReviewed: json['isReviewed'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'emiratesId': emiratesId,
    'isReviewed': isReviewed,
  };
}
