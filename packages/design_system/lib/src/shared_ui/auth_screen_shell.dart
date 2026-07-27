import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

const _kGradientStart = Color(0xFF10412F);
const _kHeaderTop = 205.0;
const _kLogoTop = 85.0;
const _kLogoWidth = 225.0;
const _kLogoHeight = 73.0;
const _kCardTopRadius = 48.0;
const _kHorizontalPadding = 20.0;
const _kVerticalPadding = 64.0;

const _kBackIconSize = 24.0;
const _kBackTop = 56.0;

/// Gradient header + white rounded-card scaffold shared by authentication and
/// registration screens.
///
/// The gradient background and Sanad wordmark are fixed at the top. The white
/// card sits at a constant offset (`_kHeaderTop`) from the top of the screen
/// and always fills the remaining height — its size never adjusts to [child].
///
/// [child] is placed inside the card with 20 dp horizontal and 64 dp vertical
/// padding (matching the Figma `Signup` / `OTP` / `Select Account Type` specs).
///
/// When [onBack] is provided, a white chevron is shown on the gradient header
/// (Figma `Bars / Nav Bars: Standard` on Organization Details and later steps).
///
/// Usage:
/// ```dart
/// AuthScreenShell(
///   onBack: () => context.pop(),
///   child: Column(children: [ ... ]),
/// )
/// ```
class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    required this.child,
    super.key,
    this.onBack,
  });

  final Widget child;

  /// When non-null, renders a back chevron on the gradient header.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Gradient background ──────────────────────────────────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kGradientStart, Colors.black],
              ),
            ),
          ),
          // ── Sanad logo ───────────────────────────────────────────────────
          Positioned(
            top: responsiveDimension(_kLogoTop),
            left: 0,
            right: 0,
            child: Center(
              child: AppSvgPicture.asset(
                AppSvgs.sanadLogo,
                width: responsiveDimension(_kLogoWidth),
                height: responsiveDimension(_kLogoHeight),
              ),
            ),
          ),
          // ── Back chevron (optional) ──────────────────────────────────────
          if (onBack != null)
            Positioned(
              top: responsiveDimension(_kBackTop),
              left: responsiveDimension(_kHorizontalPadding),
              child: GestureDetector(
                onTap: onBack,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.chevron_left,
                  size: responsiveDimension(_kBackIconSize),
                  color: colors.white,
                ),
              ),
            ),
          // ── White card (scrollable when content exceeds height) ──────────
          Positioned(
            top: responsiveDimension(_kHeaderTop),
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    responsiveDimension(_kCardTopRadius),
                  ),
                  topRight: Radius.circular(
                    responsiveDimension(_kCardTopRadius),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final vPad =
                        responsiveDimension(_kVerticalPadding);
                    final hPad =
                        responsiveDimension(_kHorizontalPadding);
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: vPad,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight - vPad * 2,
                        ),
                        child: IntrinsicHeight(child: child),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
