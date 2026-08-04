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

  /// Routes that require an authenticated session.
  static const protected = <String>{
    home,
    ...AccountSettingsRoutes.protectedRoutes,
  };
}
