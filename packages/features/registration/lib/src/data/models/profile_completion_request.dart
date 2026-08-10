import 'package:auth/auth.dart';

/// Request body for completing provider profile (`CreateProviderProfileDto`).
///
/// Shared by both individual and organization providers; [userType]
/// discriminates which of the optional fields the backend expects.
class ProfileCompletionRequest {
  const ProfileCompletionRequest({
    required this.emiratesIdFrontId,
    required this.emiratesIdBackId,
    required this.userType,
    this.tradeLicenseId,
    this.fullName,
    this.businessName,
    this.representativeFullName,
  });

  final String emiratesIdFrontId;
  final String emiratesIdBackId;
  final UserType userType;
  final String? tradeLicenseId;

  // Individual provider fields.
  final String? fullName;

  // Organization provider fields.
  final String? businessName;
  final String? representativeFullName;

  Map<String, dynamic> toJson() => {
    'emiratesIdFrontId': emiratesIdFrontId,
    'emiratesIdBackId': emiratesIdBackId,
    'userType': UserType.toJson(userType),
    if (tradeLicenseId != null) 'tradeLicenseId': tradeLicenseId,
    if (fullName != null) 'fullName': fullName,
    if (businessName != null) 'businessName': businessName,
    if (representativeFullName != null)
      'representativeFullName': representativeFullName,
  };
}
