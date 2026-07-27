import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

const _headerTop = 205.0;
const _cardHorizontalPadding = 20.0;
const _cardVerticalPadding = 64.0;
const _cardTopRadius = 48.0;
const _cardBottomRadius = 24.0;
const _outerRadius = 32.0;
const _logoTop = 85.0;
const _logoWidth = 225.0;
const _logoHeight = 73.0;

/// Header gradient — `#10412F` → black (Figma `paint0_linear_0_38`, node
/// `2560:24650`).
const _headerGradientStart = Color(0xFF10412F);

/// Shared gradient header + rounded white card shell used by all three
/// invitation-flow screens (Figma `2560:24811`).
///
/// The gradient and rounded frame are drawn natively (`Container` +
/// `LinearGradient`) rather than as a flattened background image — only the
/// Sanad wordmark (`AppSvgs.sanadLogo`) is a downloaded asset.
class InvitationScreenShell extends StatelessWidget {
  const InvitationScreenShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_headerGradientStart, Colors.black],
              ),
            ),
          ),
          Positioned(
            top: responsiveDimension(_logoTop),
            left: 0,
            right: 0,
            child: Center(
              child: AppSvgPicture.asset(
                AppSvgs.sanadLogo,
                width: responsiveDimension(_logoWidth),
                height: responsiveDimension(_logoHeight),
              ),
            ),
          ),
          Positioned(
            top: responsiveDimension(_headerTop),
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(responsiveDimension(_cardTopRadius)),
                  topRight: Radius.circular(
                    responsiveDimension(_cardTopRadius),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsiveDimension(_cardHorizontalPadding),
                    vertical: responsiveDimension(_cardVerticalPadding),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
