import 'package:auth/auth.dart' show UserType;

/// Backend endpoints for signed-in account settings.
abstract final class AccountSettingsApiPaths {
  AccountSettingsApiPaths._();

  static const String accountSettings = 'account-settings';

  /// `GET` — full account details for provider-owner accounts (individual
  /// and organization) and their workers/managers.
  static const String serviceProviderProfile = 'service-provider/profile';

  /// `GET` — full account details for the client persona.
  static const String clientProfile = 'client/profile';

  /// `GET` — full account details for the admin persona.
  static const String adminProfile = 'admin/profile';

  /// Resolves the persona-appropriate profile-read endpoint for [userType].
  /// All three envelopes share the identical response shape (`userType`,
  /// `status`, `accountSettings{...}`) — only the path differs by persona.
  static String profilePathFor(UserType userType) => switch (userType) {
    UserType.individualProvider ||
    UserType.organizationProvider ||
    UserType.worker ||
    UserType.manager => serviceProviderProfile,
    UserType.client => clientProfile,
    UserType.admin => adminProfile,
  };
}
