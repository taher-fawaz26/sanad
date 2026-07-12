/// sanad_provider route paths.
abstract final class AppRoutes {
  AppRoutes._();

  static const String home = '/home';
  static const String requests = '/requests';
  static const String messages = '/messages';
  static const String settings = '/settings';
  static const String branches = '/branches';
  static const String addBranch = '/branches/add';

  /// Routes that require an authenticated session.
  static const Set<String> protected = {
    home,
    requests,
    messages,
    settings,
    branches,
    addBranch,
  };
}
