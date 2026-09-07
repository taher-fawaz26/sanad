import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Waiting for UAE PASS (Figma `7039:28597`).
///
/// UI-only for this phase (see `OAuthUaePassPage`'s class doc): "Open UAE
/// PASS again" has no real UAE PASS SDK to re-invoke yet, and "cancel" is a
/// plain back-navigation boundary — neither simulates an SDK response.
class OAuthUaePassWaitingPage extends StatelessWidget {
  /// Creates an [OAuthUaePassWaitingPage].
  const OAuthUaePassWaitingPage({super.key});

  void _openUaePassAgain() {
    // TODO(oauth-backend): re-invoke the real UAE PASS SDK flow once it
    // exists — no-op placeholder for this UI-only phase (see class doc).
  }

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
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: AppStaggeredColumn(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppSvgPicture.asset(
                            AppSvgs.uaePassWaitingMark,
                            width: responsiveDimension(64),
                            height: responsiveDimension(64),
                          ),
                          SizedBox(
                            height: responsiveDimension(AppSpacing.xxxl),
                          ),
                          Text(
                            'oauth.uae_pass_waiting_title'.tr(),
                            textAlign: TextAlign.center,
                            style: typography.title3.copyWith(
                              fontSize: 28.rfs,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: responsiveDimension(AppSpacing.sm)),
                          Text(
                            'oauth.uae_pass_waiting_subtitle'.tr(),
                            textAlign: TextAlign.center,
                            style: typography.regularNormal.copyWith(
                              color: colors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AppButton(
                label: 'oauth.open_uae_pass_again'.tr(),
                onPressed: _openUaePassAgain,
              ),
              SizedBox(height: responsiveDimension(AppSpacing.md)),
              AppButton(
                label: 'common.cancel'.tr(),
                variant: AppButtonVariant.outline,
                onPressed: () => context.pop(),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.lg)),
            ],
          ),
        ),
      ),
    );
  }
}
