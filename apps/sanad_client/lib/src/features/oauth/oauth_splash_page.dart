import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_routes.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';
import 'package:sanad_client/src/routing/client_routes.dart';

/// Client OAuth-flow splash (Figma `6979:27187`).
///
/// A static gradient + glow composition behind the sparkle/check mark. After a
/// fixed delay this screen decides where to go based on the session that
/// `SessionManager.restore()` already rehydrated during DI bootstrap (in
/// `configureDependencies()`, before the router is even built):
///
/// - **authenticated, profile set up** → the app (`ClientRoutes.home`);
/// - **authenticated, name still null** → resume profile setup (`Enter Name`),
///   so a client who quit mid-setup is not silently dropped into an app with
///   no name (matches the backend `ACTIVE + name == null` contract);
/// - **signed out** → the OAuth entry screen.
///
/// This reuses the shared session lifecycle (`AuthStatusNotifier` +
/// `SessionManager`) rather than duplicating a sign-in check — the earlier
/// version unconditionally went to the OAuth screen, which is why a restored
/// session never opened the app on relaunch.
class OAuthSplashPage extends StatefulWidget {
  /// Creates an [OAuthSplashPage].
  const OAuthSplashPage({super.key});

  @override
  State<OAuthSplashPage> createState() => _OAuthSplashPageState();
}

class _OAuthSplashPageState extends State<OAuthSplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Session restoration already ran during DI bootstrap, so the auth state
    // is authoritative by the time this screen mounts. Navigate as soon as
    // the first frame is up rather than holding an artificial timer — the
    // splash entrance animation runs in parallel and must never block the
    // handoff into the app.
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go(_destination());
  }

  /// The post-splash destination, decided from the already-restored session.
  ///
  /// Pure and synchronous: `SessionManager.restore()` ran during bootstrap, so
  /// `AuthStatusNotifier` and `SessionManager` are authoritative by the time
  /// this screen is on-screen. No API call is made here.
  String _destination() {
    final isAuthenticated =
        sl<AuthStatusNotifier>().status == AuthStatus.authenticated;
    if (!isAuthenticated) return OAuthRoutes.screen;

    // ACTIVE session with no display name yet ⇒ profile setup never finished.
    final hasName =
        sl<SessionManager>().displayName?.trim().isNotEmpty ?? false;
    return hasName ? ClientRoutes.home : AccountSetupRoutes.enterName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.8, -1),
            end: Alignment(0.8, 1),
            colors: [Color(0xFFC9FBD8), Color(0xFFF9F9FA)],
          ),
        ),
        child: Center(
          child:
              SizedBox(
                width: responsiveDimension(200),
                height: responsiveDimension(200),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7CE495).withValues(alpha: 0.55),
                        const Color(0xFF7CE495).withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: Center(
                    child: AppSvgPicture.asset(
                      AppSvgs.onboardingSplashMark,
                      width: responsiveDimension(94),
                      height: responsiveDimension(92),
                    ),
                  ),
                ),
              ).appFadeScale(
                context,
                duration: AppMotionDuration.emphasis,
                curve: AppMotionCurve.emphasizedDecelerate,
                beginScale: 0.9,
              ),
        ),
      ),
    );
  }
}
