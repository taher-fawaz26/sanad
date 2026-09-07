import 'package:app_animations/app_animations.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';
import 'package:sanad_client/src/features/oauth/uae_pass_device_connection_illustration.dart';

/// Continue in UAE PASS (Figma `7030:28395`).
///
/// UI-only for this phase: real UAE PASS SDK integration (opening the app,
/// handling the approval callback, creating a session) is a separate, later
/// task. Tapping "Open UAE PASS" only advances the UI flow to the [waiting
/// screen](../oauth_uae_pass_waiting_page.dart) — it does not invoke any SDK.
class OAuthUaePassPage extends StatelessWidget {
  /// Creates an [OAuthUaePassPage].
  const OAuthUaePassPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Scaffold(
      appBar: AppNavBar(
        title: '',
        showBackButton: true,
        onLeadingTap: () => context.pop(),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsiveDimension(AppSpacing.xxl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: AppStaggeredColumn(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: responsiveDimension(AppSpacing.xxxxl)),
                      const UaePassDeviceConnectionIllustration(),
                      SizedBox(height: responsiveDimension(AppSpacing.xxl)),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'oauth.uae_pass_title'.tr(),
                          textAlign: TextAlign.center,
                          style: typography.title3.copyWith(
                            fontSize: 28.rfs,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: responsiveDimension(AppSpacing.sm)),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'oauth.uae_pass_subtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: typography.regularNormal.copyWith(
                            color: colors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppButton(
                label: 'oauth.open_uae_pass'.tr(),
                // No real UAE PASS SDK integration in this UI-only phase —
                // this is a navigation-flow boundary, not a fake auth
                // success: the real SDK callback would eventually land here
                // (or later on the waiting screen) once it exists.
                onPressed: () => context.push(OAuthRoutes.uaePassWaiting),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.lg)),
            ],
          ),
        ),
      ),
    );
  }
}
