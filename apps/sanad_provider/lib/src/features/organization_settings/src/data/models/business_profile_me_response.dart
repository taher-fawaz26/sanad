import 'package:sanad_provider/src/features/organization_settings/src/data/models/me_media_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/service_provider_category_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/business_profile_status.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/social_profiles_entity.dart';

/// Mirrors `MeBusinessProfileDto` exactly — nested under `businessProfile` in
/// the `GET /settings` response.
///
/// Does NOT carry `personalLegalData`/`tradeLicenseLegalData` — those live
/// under the separate `GET service-provider/legal-data` endpoint (see
/// `LegalDataRemoteDataSource`); the repository layer merges them into
/// [OrganizationProfileEntity] from that other call.
class BusinessProfileMeResponse {
  const BusinessProfileMeResponse({
    required this.id,
    required this.categories,
    required this.status,
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
    this.rejectionReason,
  });

  factory BusinessProfileMeResponse.fromJson(Map<String, dynamic> json) {
    final coverImage = json['coverImage'] as Map<String, dynamic>?;
    final profileImage = json['profileImage'] as Map<String, dynamic>?;
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
          : MeMediaResponse.fromJson(coverImage),
      profileImage: profileImage == null
          ? null
          : MeMediaResponse.fromJson(profileImage),
      description: json['description'] as String?,
      categories: (json['categories'] as List<dynamic>)
          .map(
            (item) => ServiceProviderCategoryResponse.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      socialProfiles: socialProfiles,
      status: BusinessProfileStatus.fromJson(json['status'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Reverse of [toEntity] — builds the cache-serializable DTO from an
  /// entity that came from a local merge (image upload, description/
  /// category/social-profile PATCH) rather than a fresh `GET /settings`
  /// response, so that merge can still be written through to the cache.
  factory BusinessProfileMeResponse.fromEntity(
    OrganizationProfileEntity entity,
  ) {
    final social = entity.socialProfiles;
    return BusinessProfileMeResponse(
      id: entity.id,
      businessName: entity.businessName,
      businessEmail: entity.businessEmail,
      businessPhone: entity.businessPhone,
      ownerEmiratesId: entity.ownerEmiratesId,
      tradeLicenseNumber: entity.tradeLicenseNumber,
      coverImage: entity.coverImage == null
          ? null
          : MeMediaResponse(
              id: entity.coverImage!.id,
              url: entity.coverImage!.url,
            ),
      profileImage: entity.profileImage == null
          ? null
          : MeMediaResponse(
              id: entity.profileImage!.id,
              url: entity.profileImage!.url,
            ),
      description: entity.description,
      categories: entity.categories
          .map(
            (category) => ServiceProviderCategoryResponse(
              id: category.id,
              name: category.name,
            ),
          )
          .toList(),
      socialProfiles: social == null
          ? null
          : {
              if (social.facebook != null) 'facebook': social.facebook,
              if (social.tiktok != null) 'tiktok': social.tiktok,
              if (social.instagram != null) 'instagram': social.instagram,
              if (social.x != null) 'x': social.x,
              if (social.websiteUrl != null) 'website': social.websiteUrl,
            },
      status: entity.status,
      rejectionReason: entity.rejectionReason,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  final String id;
  final String? businessName;
  final String? businessEmail;
  final String? businessPhone;
  final String? ownerEmiratesId;
  final String? tradeLicenseNumber;
  final MeMediaResponse? coverImage;
  final MeMediaResponse? profileImage;
  final String? description;
  final List<ServiceProviderCategoryResponse> categories;

  /// Raw `Map<String, String>` from the backend — `socialLinks`, including
  /// `website` when provided.
  final Map<String, dynamic>? socialProfiles;
  final BusinessProfileStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Cache-only serialization — round-trips through [fromJson]. Legal data
  /// is deliberately not part of this shape (see class doc), so it never
  /// enters the cache via this path.
  Map<String, dynamic> toJson() => {
    'id': id,
    'businessName': businessName,
    'businessEmail': businessEmail,
    'businessPhone': businessPhone,
    'ownerEmiratesId': ownerEmiratesId,
    'tradeLicenseNumber': tradeLicenseNumber,
    'coverImage': coverImage?.toJson(),
    'profileImage': profileImage?.toJson(),
    'description': description,
    'categories': categories.map((category) => category.toJson()).toList(),
    'socialProfiles': socialProfiles,
    'status': status.name.toUpperCase(),
    'rejectionReason': rejectionReason,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

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
    status: status,
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
