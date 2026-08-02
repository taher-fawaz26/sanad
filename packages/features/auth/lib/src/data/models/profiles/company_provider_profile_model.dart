import 'package:auth/src/domain/entities/auth_profile_entity.dart';

/// Data model for [CompanyProviderProfileEntity].
class CompanyProviderProfileModel extends CompanyProviderProfileEntity {
  const CompanyProviderProfileModel({
    required super.id,
    required super.businessName,
    required super.businessEmail,
    required super.representativeFullName,
    required super.representativeEmail,
    required super.emiratesIdFrontId,
    required super.emiratesIdBackId,
    required super.tradeLicenseId,
    required super.isReviewed,
    super.tradeLicenseNumber,
    super.representativeEmiratesId,
  });

  factory CompanyProviderProfileModel.fromJson(Map<String, dynamic> json) {
    return CompanyProviderProfileModel(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      businessEmail: json['businessEmail'] as String,
      tradeLicenseNumber: json['tradeLicenseNumber'] as String?,
      representativeFullName: json['representativeFullName'] as String,
      representativeEmail: json['representativeEmail'] as String,
      representativeEmiratesId: json['representativeEmiratesId'] as String?,
      emiratesIdFrontId: json['emiratesIdFrontId'] as String,
      emiratesIdBackId: json['emiratesIdBackId'] as String,
      tradeLicenseId: json['tradeLicenseId'] as String,
      isReviewed: json['isReviewed'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessName': businessName,
    'businessEmail': businessEmail,
    'tradeLicenseNumber': tradeLicenseNumber,
    'representativeFullName': representativeFullName,
    'representativeEmail': representativeEmail,
    'representativeEmiratesId': representativeEmiratesId,
    'emiratesIdFrontId': emiratesIdFrontId,
    'emiratesIdBackId': emiratesIdBackId,
    'tradeLicenseId': tradeLicenseId,
    'isReviewed': isReviewed,
  };
}
