import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One-off illustration colors (Figma `7030:28395`) — not design-system
/// tokens, since this device-mock graphic is bespoke to this illustration
/// (mirrors `OAuthSplashPage`'s own hardcoded gradient for the same reason).
const _deviceOutline = Color(0xFF8A8D90);
const _uaePassPillBackground = Color(0xFF0B1916);

/// Phone ↔ laptop "connection" graphic shared by every screen in the UAE
/// PASS flow that shows the two devices syncing (`7030:28397` / `7039:28513`
/// on the "Continue in UAE PASS" and "We collect data from UAE PASS"
/// screens) — a single shared widget so the illustration is not duplicated
/// per screen.
///
/// Always LTR regardless of app locale — this mirrors [AppPhoneField]'s own
/// established convention (`+971` prefix + digits) for inherently-physical
/// content that isn't reading direction: the illustration shows a device
/// syncing with a laptop, not text.
class UaePassDeviceConnectionIllustration extends StatelessWidget {
  /// Creates a [UaePassDeviceConnectionIllustration].
  const UaePassDeviceConnectionIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: double.infinity,
        height: responsiveDimension(118),
        child: Stack(
          children: [
            Positioned(
              top: responsiveDimension(AppSpacing.lg),
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: responsiveDimension(64),
                    child: const Center(child: _PhoneMock()),
                  ),
                  SizedBox(width: responsiveDimension(AppSpacing.md)),
                  AppSvgPicture.asset(
                    AppSvgs.uaePassConnectionBridge,
                    width: responsiveDimension(117.244),
                    height: responsiveDimension(24),
                  ),
                  SizedBox(width: responsiveDimension(AppSpacing.md)),
                  SizedBox(
                    width: responsiveDimension(84),
                    child: const Center(child: _LaptopMock()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneMock extends StatelessWidget {
  const _PhoneMock();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: responsiveDimension(44),
      height: responsiveDimension(86),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: responsiveDimension(44),
            height: responsiveDimension(86),
            padding: EdgeInsets.all(responsiveDimension(4)),
            decoration: BoxDecoration(
              border: Border.all(
                color: _deviceOutline,
                width: responsiveDimension(2),
              ),
              borderRadius: BorderRadius.circular(responsiveDimension(12)),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: responsiveDimension(14),
                height: responsiveDimension(4),
                decoration: BoxDecoration(
                  color: _deviceOutline,
                  borderRadius: BorderRadius.circular(responsiveDimension(2)),
                ),
              ),
            ),
          ),
          // Figma `7030:28417` — sparkle centered inside the phone outline.
          Positioned(
            left: responsiveDimension(9),
            top: responsiveDimension(27),
            child: AppSvgPicture.asset(
              AppSvgs.uaePassDeviceSparkle,
              width: responsiveDimension(27),
              height: responsiveDimension(28),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaptopMock extends StatelessWidget {
  const _LaptopMock();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: responsiveDimension(82),
          height: responsiveDimension(55),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: _deviceOutline,
              width: responsiveDimension(2),
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(responsiveDimension(4)),
              topRight: Radius.circular(responsiveDimension(4)),
            ),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsiveDimension(9.96),
              vertical: responsiveDimension(4.98),
            ),
            decoration: BoxDecoration(
              color: _uaePassPillBackground,
              borderRadius: BorderRadius.circular(responsiveDimension(8)),
            ),
            child: Text(
              'UAE PASS',
              style: context.appTypography.tinyNormal.copyWith(
                fontSize: responsiveDimension(10),
                fontWeight: FontWeight.w700,
                height: 1,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Container(
          width: responsiveDimension(92),
          height: responsiveDimension(5),
          decoration: BoxDecoration(
            color: _deviceOutline,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(responsiveDimension(2)),
              bottomRight: Radius.circular(responsiveDimension(2)),
            ),
          ),
        ),
      ],
    );
  }
}
