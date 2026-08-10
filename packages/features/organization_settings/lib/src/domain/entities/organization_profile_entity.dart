import 'package:equatable/equatable.dart';
import 'package:organization_settings/src/domain/entities/business_profile_status.dart';
import 'package:organization_settings/src/domain/entities/category_entity.dart';
import 'package:organization_settings/src/domain/entities/me_media_entity.dart';
import 'package:organization_settings/src/domain/entities/personal_legal_data_entity.dart';
import 'package:organization_settings/src/domain/entities/social_profiles_entity.dart';
import 'package:organization_settings/src/domain/entities/trade_license_legal_data_entity.dart';

/// The organization's business profile — single source of truth for the
/// Organization Settings feature, sourced from `GET /settings`
/// (`MeBusinessProfileDto`).
///
/// Every section on the general settings page (Identity, Category, Contact
/// Information, Social Profiles, Working Hours, header) reads from this one
/// root entity instead of independent models or mocked state.
///
/// [personalLegalData]/[tradeLicenseLegalData] are the exception: the
/// `/settings` response no longer carries them, so the repository layer
/// merges them in separately from `GET service-provider/legal-data`
/// (`LegalDataRemoteDataSource`) — they stay on this entity purely so the
/// Compliance Documents section keeps reading from one place.
class OrganizationProfileEntity extends Equatable {
  const OrganizationProfileEntity({
    required this.id,
    required this.categories,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.businessName,
    this.description,
    this.businessEmail,
    this.businessPhone,
    this.ownerEmiratesId,
    this.tradeLicenseNumber,
    this.coverImage,
    this.profileImage,
    this.socialProfiles,
    this.personalLegalData,
    this.tradeLicenseLegalData,
    this.rejectionReason,
  });

  final String id;

  /// Null until set in business settings.
  final String? businessName;
  final String? description;

  /// Null until verified and set.
  final String? businessEmail;

  /// Null until verified and set.
  final String? businessPhone;

  /// Individual providers only.
  final String? ownerEmiratesId;

  /// Company providers only.
  final String? tradeLicenseNumber;
  final MeMediaEntity? coverImage;
  final MeMediaEntity? profileImage;
  final List<CategoryEntity> categories;
  final SocialProfilesEntity? socialProfiles;
  final PersonalLegalDataEntity? personalLegalData;
  final TradeLicenseLegalDataEntity? tradeLicenseLegalData;
  final BusinessProfileStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Collapses [status] to the boolean the header/UI historically branched
  /// on: `true` once the profile is live to customers, `false` for every
  /// other state (`inReview`, `expired`, `suspended`).
  bool get isReviewed => status == BusinessProfileStatus.active;

  OrganizationProfileEntity copyWith({
    PersonalLegalDataEntity? personalLegalData,
    TradeLicenseLegalDataEntity? tradeLicenseLegalData,
    String? description,
    List<CategoryEntity>? categories,
    SocialProfilesEntity? socialProfiles,
  }) => OrganizationProfileEntity(
    id: id,
    categories: categories ?? this.categories,
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    businessName: businessName,
    description: description ?? this.description,
    businessEmail: businessEmail,
    businessPhone: businessPhone,
    ownerEmiratesId: ownerEmiratesId,
    tradeLicenseNumber: tradeLicenseNumber,
    coverImage: coverImage,
    profileImage: profileImage,
    socialProfiles: socialProfiles ?? this.socialProfiles,
    personalLegalData: personalLegalData ?? this.personalLegalData,
    tradeLicenseLegalData: tradeLicenseLegalData ?? this.tradeLicenseLegalData,
    rejectionReason: rejectionReason,
  );

  @override
  List<Object?> get props => [
    id,
    businessName,
    description,
    businessEmail,
    businessPhone,
    ownerEmiratesId,
    tradeLicenseNumber,
    coverImage,
    profileImage,
    categories,
    socialProfiles,
    personalLegalData,
    tradeLicenseLegalData,
    status,
    rejectionReason,
    createdAt,
    updatedAt,
  ];
}
