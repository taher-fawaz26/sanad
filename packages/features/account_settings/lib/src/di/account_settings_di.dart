/// Dependency registration for account_settings.
///
/// Empty until real account use cases (profile, security, …) are added.
/// Logout uses AuthBloc from the `auth` package.
abstract final class AccountSettingsDI {
  AccountSettingsDI._();

  /// Registers account_settings dependencies with GetIt.
  static void init() {}
}
