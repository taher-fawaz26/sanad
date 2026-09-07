import 'package:account_settings/account_settings.dart';

/// Static route constants for the client app.
///
/// Mirrors `sanad_provider`'s `AppRoutes` so both apps share the same
/// discipline: no route strings appear inline in pages, all routing
/// referenced through this class.
abstract final class ClientRoutes {
  ClientRoutes._();

  static const home = '/home';
  static const offline = '/offline';

  /// Client profile. A real, permanent destination — unlike the AI chat
  /// prototype's routes, not gated by `kReleaseMode`. Today it is reachable
  /// only from that prototype's Home header, so it is registered but
  /// unadvertised in a release build rather than unreachable outright.
  static const profile = '/profile';

  /// Full-screen 403 page — reachable as an explicit `denyRedirect` target
  /// for any route rule that wants a dedicated "Access Denied" screen.
  static const forbidden = '/403';

  /// Routes that require an authenticated session.
  static const protected = <String>{
    home,
    ...AccountSettingsRoutes.protectedRoutes,
  };
}
