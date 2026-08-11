/// Route paths owned by the account_settings feature.
abstract final class AccountSettingsRoutes {
  AccountSettingsRoutes._();

  /// Account settings hub — Figma settings menu → Account settings.
  static const String hub = '/settings/account';

  /// Routes that require an authenticated session.
  static const Set<String> protectedRoutes = {hub};
}
