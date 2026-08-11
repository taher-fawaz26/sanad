import 'package:equatable/equatable.dart';

/// Params for `PATCH service-provider/settings`
/// (`UpdateServiceProviderSettingsDto`).
///
/// Every field is optional on the wire — omit a field entirely (leave it
/// `null` here) to leave that part of the profile untouched. [categoryIds]
/// must be real backend category UUIDs (from `GET /categories`), never
/// local/mock ids. [socialProfiles] keys are limited to: `facebook`, `x`,
/// `tiktok`, `instagram`, `website`.
class UpdateServiceProviderSettingsParams extends Equatable {
  const UpdateServiceProviderSettingsParams({
    this.description,
    this.categoryIds,
    this.socialProfiles,
  });

  /// Max length 350.
  final String? description;

  /// Real backend category UUIDs.
  final List<String>? categoryIds;

  /// Keys limited to: `facebook`, `x`, `tiktok`, `instagram`, `website`.
  final Map<String, String>? socialProfiles;

  @override
  List<Object?> get props => [description, categoryIds, socialProfiles];
}
