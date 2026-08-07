import 'package:equatable/equatable.dart';
import 'package:organization_settings/src/domain/entities/category_entity.dart';
import 'package:organization_settings/src/domain/entities/media_entity.dart';
import 'package:organization_settings/src/domain/entities/personal_legal_data_entity.dart';
import 'package:organization_settings/src/domain/entities/social_profiles_entity.dart';
import 'package:organization_settings/src/domain/entities/trade_license_legal_data_entity.dart';

/// The organization's business profile — `BusinessProfileMeResponseDto`.
///
/// Nested under [OrganizationSettingsEntity.profile]; every field here mirrors
/// a backend field 1:1, nullable exactly where the backend allows null.
class OrganizationProfileEntity extends Equatable {
  const OrganizationProfileEntity({
    required this.id,
    required this.categories,
    required this.isReviewed,
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
  final MediaEntity? coverImage;
  final MediaEntity? profileImage;
  final List<CategoryEntity> categories;
  final SocialProfilesEntity? socialProfiles;
  final PersonalLegalDataEntity? personalLegalData;
  final TradeLicenseLegalDataEntity? tradeLicenseLegalData;
  final bool isReviewed;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    isReviewed,
    rejectionReason,
    createdAt,
    updatedAt,
  ];
}
