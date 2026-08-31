import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/oauth/oauth_language_selector.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';

/// Figma `sign in` (`3026:19575`) via `packages/auth`'s `AuthPage` — reused
/// verbatim here rather than exported as a new asset (known-good SVG already
/// in the codebase for this exact icon).
const _googleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#4285F4"
    d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853"
    d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05"
    d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"/>
  <path fill="#EA4335"
    d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>
''';

/// Google icon at Figma `6974:25087`'s literal size — [AppButton] centers a
/// smaller icon inside its fixed 24 dp icon box, so setting this explicitly
/// (Figma: 18 dp, vs. Phone's 24 dp) doesn't require touching the shared
/// button component.
const _googleIconSize = 18.0;

/// OAuth screen — the authentication-method entry point (Figma `6974:25087`).
///
/// From here the user chooses UAE PASS, Email, Google, or Phone. Email,
/// Phone and UAE PASS navigate to their own UI-only screens; Google has no
/// screen in this phase yet, so its `onPressed` stays a documented no-op.
class OAuthScreen extends StatelessWidget {
  /// Creates an [OAuthScreen].
  const OAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    final orDivider = Row(
      children: [
        const Expanded(child: AppDivider()),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsiveDimension(AppSpacing.md),
          ),
          child: Text(
            // Figma renders this divider label in uppercase ("OR") while the
            // shared `common.or` key stays title-case ("Or") for its other,
            // non-uppercase call sites — transformed here rather than in the
            // shared string.
            'common.or'.tr().toUpperCase(),
            style: typography.tinyNormal.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Expanded(child: AppDivider()),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsiveDimension(AppSpacing.xxl),
          ),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: responsiveDimension(AppSpacing.sm),
                  ),
                  child: const OAuthLanguageSelector(),
                ),
              ),
              // Bottom-anchored content on tall screens (matches Figma), but
              // scrolls instead of overflowing on short ones — a plain
              // Column+Spacer here isn't safe across the full range of
              // supported device heights.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'oauth.get_started_title'.tr(),
                            textAlign: TextAlign.center,
                            style: typography.title3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: responsiveDimension(AppSpacing.md)),
                          Text(
                            'oauth.get_started_subtitle'.tr(),
                            textAlign: TextAlign.center,
                            style: typography.smallNormal.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          SizedBox(height: responsiveDimension(AppSpacing.md)),
                          AppButton(
                            label: 'oauth.continue_uae_pass'.tr(),
                            iconPosition: AppButtonIconPosition.left,
                            icon: AppSvgPicture.asset(AppSvgs.uaePassLogo),
                            onPressed: () => context.push(OAuthRoutes.uaePass),
                          ),
                          SizedBox(height: responsiveDimension(AppSpacing.lg)),
                          orDivider,
                          SizedBox(height: responsiveDimension(AppSpacing.lg)),
                          AppButton(
                            label: 'oauth.continue_email'.tr(),
                            variant: AppButtonVariant.secondary,
                            intent: AppButtonIntent.neutral,
                            onPressed: () => context.push(OAuthRoutes.email),
                          ),
                          SizedBox(height: responsiveDimension(AppSpacing.md)),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'oauth.continue_google'.tr(),
                                  variant: AppButtonVariant.secondary,
                                  intent: AppButtonIntent.neutral,
                                  iconPosition: AppButtonIconPosition.center,
                                  icon: SvgPicture.string(
                                    _googleLogoSvg,
                                    width: responsiveDimension(
                                      _googleIconSize,
                                    ),
                                    height: responsiveDimension(
                                      _googleIconSize,
                                    ),
                                  ),
                                  // No backend yet — documented boundary for
                                  // this phase.
                                  onPressed: () {},
                                ),
                              ),
                              SizedBox(
                                width: responsiveDimension(AppSpacing.md),
                              ),
                              Expanded(
                                child: AppButton(
                                  label: 'oauth.continue_phone'.tr(),
                                  variant: AppButtonVariant.secondary,
                                  intent: AppButtonIntent.neutral,
                                  iconPosition: AppButtonIconPosition.center,
                                  icon: AppSvgPicture.asset(
                                    AppSvgs.smartphoneDevice,
                                  ),
                                  onPressed: () =>
                                      context.push(OAuthRoutes.phone),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: responsiveDimension(AppSpacing.lg)),
                          Text.rich(
                            textAlign: TextAlign.center,
                            TextSpan(
                              style: typography.tinyNormal.copyWith(
                                color: colors.textSecondary,
                              ),
                              children: [
                                TextSpan(text: 'oauth.terms_prefix'.tr()),
                                TextSpan(
                                  text: 'oauth.terms_link'.tr(),
                                  style: TextStyle(color: colors.primary),
                                  // No terms destination in this UI-only
                                  // phase.
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {},
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: responsiveDimension(AppSpacing.xxl)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
