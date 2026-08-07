import 'package:organization_settings/src/data/models/national_id_response.dart';
import 'package:organization_settings/src/data/models/service_provider_category_response.dart';
import 'package:organization_settings/src/data/models/service_provider_media_response.dart';
import 'package:organization_settings/src/data/models/trade_license_response.dart';
import 'package:organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:organization_settings/src/domain/entities/social_profiles_entity.dart';

/// Mirrors `BusinessProfileMeResponseDto` exactly.
class BusinessProfileMeResponse {
  const BusinessProfileMeResponse({
    required this.id,
    required this.categories,
    required this.isReviewed,
    required this.createdAt,
    required this.updatedAt,
    this.businessName,
    this.businessEmail,
    this.businessPhone,
    this.ownerEmiratesId,
    this.tradeLicenseNumber,
    this.coverImage,
    this.profileImage,
    this.description,
    this.socialProfiles,
    this.personalLegalData,
    this.tradeLicenseLegalData,
    this.rejectionReason,
  });

  factory BusinessProfileMeResponse.fromJson(Map<String, dynamic> json) {
    final coverImage = json['coverImage'] as Map<String, dynamic>?;
    final profileImage = json['profileImage'] as Map<String, dynamic>?;
    final personalLegalData =
        json['personalLegalData'] as Map<String, dynamic>?;
    final tradeLicenseLegalData =
        json['tradeLicenseLegalData'] as Map<String, dynamic>?;
    final socialProfiles = json['socialProfiles'] as Map<String, dynamic>?;

    return BusinessProfileMeResponse(
      id: json['id'] as String,
      businessName: json['businessName'] as String?,
      businessEmail: json['businessEmail'] as String?,
      businessPhone: json['businessPhone'] as String?,
      ownerEmiratesId: json['ownerEmiratesId'] as String?,
      tradeLicenseNumber: json['tradeLicenseNumber'] as String?,
      coverImage: coverImage == null
          ? null
          : ServiceProviderMediaResponse.fromJson(coverImage),
      profileImage: profileImage == null
          ? null
          : ServiceProviderMediaResponse.fromJson(profileImage),
      description: json['description'] as String?,
      categories: (json['categories'] as List<dynamic>)
          .map(
            (item) => ServiceProviderCategoryResponse.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      socialProfiles: socialProfiles,
      personalLegalData: personalLegalData == null
          ? null
          : NationalIdResponse.fromJson(personalLegalData),
      tradeLicenseLegalData: tradeLicenseLegalData == null
          ? null
          : TradeLicenseResponse.fromJson(tradeLicenseLegalData),
      isReviewed: json['isReviewed'] as bool,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String? businessName;
  final String? businessEmail;
  final String? businessPhone;
  final String? ownerEmiratesId;
  final String? tradeLicenseNumber;
  final ServiceProviderMediaResponse? coverImage;
  final ServiceProviderMediaResponse? profileImage;
  final String? description;
  final List<ServiceProviderCategoryResponse> categories;

  /// Raw `Map<String, String>` from the backend — `socialLinks`, including
  /// `website` when provided.
  final Map<String, dynamic>? socialProfiles;
  final NationalIdResponse? personalLegalData;
  final TradeLicenseResponse? tradeLicenseLegalData;
  final bool isReviewed;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrganizationProfileEntity toEntity() => OrganizationProfileEntity(
    id: id,
    businessName: businessName,
    businessEmail: businessEmail,
    businessPhone: businessPhone,
    ownerEmiratesId: ownerEmiratesId,
    tradeLicenseNumber: tradeLicenseNumber,
    coverImage: coverImage?.toEntity(),
    profileImage: profileImage?.toEntity(),
    description: description,
    categories: categories.map((category) => category.toEntity()).toList(),
    socialProfiles: _socialProfilesEntity(),
    personalLegalData: personalLegalData?.toEntity(),
    tradeLicenseLegalData: tradeLicenseLegalData?.toEntity(),
    isReviewed: isReviewed,
    rejectionReason: rejectionReason,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  SocialProfilesEntity? _socialProfilesEntity() {
    final map = socialProfiles;
    if (map == null) return null;

    return SocialProfilesEntity(
      facebook: map['facebook'] as String?,
      tiktok: map['tiktok'] as String?,
      instagram: map['instagram'] as String?,
      x: map['x'] as String?,
      websiteUrl: map['website'] as String?,
    );
  }
}
