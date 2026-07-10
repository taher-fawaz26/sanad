abstract final class ValidationMessageKeys {
  ValidationMessageKeys._();

  static const String formRequired = 'validation.form.required';
  static const String formEmailInvalid = 'validation.form.email_invalid';
  static const String formPhoneInvalid = 'validation.form.phone_invalid';
  static const String formEmiratesId = 'validation.form.emirates_id';
  static const String formUrlInvalid = 'validation.form.url_invalid';
  static const String formIbanInvalid = 'validation.form.iban_invalid';
  static const String formNumberInvalid = 'validation.form.number_invalid';
  static const String formLatitudeRange = 'validation.form.latitude_range';
  static const String formLongitudeRange = 'validation.form.longitude_range';
  static const String formRadiusPositive = 'validation.form.radius_positive';
  static const String formMinAge = 'validation.form.min_age';
  static const String formSwiftInvalid = 'validation.form.swift_invalid';
  static const String formNameInvalid = 'validation.form.name_invalid';
  static const String formGoogleMapsUrlInvalid =
      'validation.form.google_maps_url_invalid';
  static const String passwordPolicy = 'validation.form.password_policy';
  static const String minLengthPrefix = 'validation.form.min_length::';
  static const String maxLengthPrefix = 'validation.form.max_length::';

  static String minLength(int min) => '$minLengthPrefix$min';
  static String maxLength(int max) => '$maxLengthPrefix$max';

  static const String registrationStepIncomplete =
      'validation.registration.step_incomplete';
  static const String registrationBranchesMinOne =
      'validation.registration.branches_min_one';
  static const String registrationServicesAtLeastOne =
      'validation.registration.services_at_least_one';
  static const String registrationDocumentsMissing =
      'validation.registration.documents_missing';
  static const String registrationDocumentsUploadAll =
      'validation.registration.documents_upload_all';
  static const String registrationPaymentAtLeastOneMethod =
      'validation.registration.payment_at_least_one_method';
  static const String registrationReviewTermsRequired =
      'validation.registration.review_terms_required';
  static const String profileRemoteEditBlockedUntilCompleted =
      'validation.profile.remote_edit_blocked_until_completed';
}
