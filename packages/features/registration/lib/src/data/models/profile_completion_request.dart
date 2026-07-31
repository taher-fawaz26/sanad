/// Request body for completing provider profile (both individual and company).
class ProfileCompletionRequest {
  const ProfileCompletionRequest({
    required this.emiratesIdFrontId,
    required this.emiratesIdBackId,
    this.tradeLicenseId,
    this.fullName,
    this.businessName,
    this.representativeFullName,
    this.representativeEmail,
  });

  final String emiratesIdFrontId;
  final String emiratesIdBackId;
  final String? tradeLicenseId;

  // Individual provider fields.
  final String? fullName;

  // Company provider fields.
  final String? businessName;
  final String? representativeFullName;
  final String? representativeEmail;

  Map<String, dynamic> toJson() => {
        'emiratesIdFrontId': emiratesIdFrontId,
        'emiratesIdBackId': emiratesIdBackId,
        if (tradeLicenseId != null) 'tradeLicenseId': tradeLicenseId,
        if (fullName != null) 'fullName': fullName,
        if (businessName != null) 'businessName': businessName,
        if (representativeFullName != null)
          'representativeFullName': representativeFullName,
        if (representativeEmail != null)
          'representativeEmail': representativeEmail,
      };
}
