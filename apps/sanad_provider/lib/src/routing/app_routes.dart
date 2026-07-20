/// sanad_provider route paths for app-shell pages.
///
/// Feature-owned routes live in their respective package route classes
/// (e.g. [BranchRoutes]). This class only declares routes owned directly
/// by the app shell.
abstract final class AppRoutes {
  AppRoutes._();

  static const String home = '/home';
  static const String requests = '/requests';
  static const String messages = '/messages';
  static const String settings = '/settings';

  /// Full-screen offline page — Figma `1528:10165`. Pushed (not replaced)
  /// so the user can pop back and open it again.
  static const String offline = '/offline';

  /// Routes that require an authenticated session.
  ///
  /// Feature-owned protected routes (e.g. [BranchRoutes.protectedRoutes])
  /// are merged in [buildProviderRouter] so the router stays the single
  /// source of truth.
  static const Set<String> protected = {
    home,
    requests,
    messages,
    settings,
  };
}
