import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/onboarding/onboarding_routes.dart';

/// Client onboarding splash (Figma `6979:27187`).
///
/// A static gradient + glow composition behind the sparkle/check mark — no
/// backend session check (that stays exclusively `packages/auth`'s own
/// `SplashPage`, used by `sanad_provider`). After a fixed delay this screen
/// hands off to the Get Started screen.
class OnboardingSplashPage extends StatefulWidget {
  /// Creates an [OnboardingSplashPage].
  const OnboardingSplashPage({super.key});

  @override
  State<OnboardingSplashPage> createState() => _OnboardingSplashPageState();
}

class _OnboardingSplashPageState extends State<OnboardingSplashPage> {
  static const _navigateAfter = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(_navigateAfter, () {
      if (mounted) context.go(OnboardingRoutes.getStarted);
    });
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
          child: SizedBox(
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
          ),
        ),
      ),
    );
  }
}
