abstract final class StorageKeys {
  StorageKeys._();

  // ── Secure storage (tokens) ───────────────────────────────────────────────
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';

  // ── Hive — user profile ───────────────────────────────────────────────────
  static const String userEntity = 'user';

  // ── Hive — app prefs ──────────────────────────────────────────────────────
  static const String onboardingSeen = 'onboarding_seen';
  static const String targetAudienceSurveyDraft =
      'target_audience_survey_draft_v1';
  static const String branchesSwipeHintSeen = 'branches_swipe_hint_seen_v1';
  static const String servicesSwipeHintSeen = 'services_swipe_hint_seen_v1';
  static const String workersSwipeHintSeen = 'workers_swipe_hint_seen_v1';
  static const String invitationsSwipeHintSeen =
      'invitations_swipe_hint_seen_v1';

  // ── Secure storage (app lock) ─────────────────────────────────────────────
  // Deliberately NOT in the Hive default box: that box is unencrypted, and a
  // security toggle that can be flipped by editing a plaintext file on a
  // rooted device is not a security toggle. These live in
  // Keychain/Keystore via SecureLocalStorage.
  static const String appLockEnabled = 'app_lock_enabled_v1';
  static const String appLockOffered = 'app_lock_offered_v1';

  // ── Hive — registration ───────────────────────────────────────────────────
  static const String registrationProgressPrefix = 'reg_progress_v1_';
  static const String lookupProviderTypes = 'lookup_provider_types_v1';
  static const String lookupCompanyTypes = 'lookup_company_types_v1';
  static const String lookupLanguages = 'lookup_languages_v1';
  static const String lookupServiceCategoriesLegacy =
      'lookup_service_categories_v1';
  static const String registrationSubmittedPrefix = 'reg_app_submitted_v1_';

  static String registrationProgress(String userId) =>
      '$registrationProgressPrefix$userId';

  static String registrationSubmitted(String userId) =>
      '$registrationSubmittedPrefix$userId';

  // ── Form field names ──────────────────────────────────────────────────────
  static const String servicesCatalogSearch = 'services_catalog_search';

  // ── Network extras ────────────────────────────────────────────────────────
  static const String dioTimeoutRetryCount = 'dio_timeout_retry_count';

  // ── Hive encryption ───────────────────────────────────────────────────────
  static String hiveEncryptionKey(String boxName) => 'hive_key_$boxName';
}
