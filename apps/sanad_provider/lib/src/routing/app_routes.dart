import 'package:account_settings/account_settings.dart';
import 'package:organization_settings/organization_settings.dart';

/// sanad_provider route paths for app-shell pages.
///
/// Feature-owned routes live in their respective package route classes
/// (e.g. OrganizationSettingsRoutes, AccountSettingsRoutes). This class
/// only declares routes owned directly by the app shell.
abstract final class AppRoutes {
  AppRoutes._();

  static const String home = '/home';
  static const String messages = '/messages';
  static const String requests = '/requests';
  static const String services = '/services';

  /// Shell Settings tab — organization KPI hub.
  static const String settings = OrganizationSettingsRoutes.hub;

  /// Full-screen offline page — Figma `1528:10165`. Pushed (not replaced)
  /// so the user can pop back and open it again.
  static const String offline = '/offline';

  /// Routes that require an authenticated session.
  ///
  /// Feature-owned protected routes are merged in buildProviderRouter.
  static const Set<String> protected = {
    home,
    messages,
    requests,
    services,
    ...OrganizationSettingsRoutes.protectedRoutes,
    ...AccountSettingsRoutes.protectedRoutes,
  };
}
