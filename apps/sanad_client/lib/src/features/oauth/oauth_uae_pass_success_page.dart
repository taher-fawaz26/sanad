import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/oauth/uae_pass_collected_details.dart';
import 'package:sanad_client/src/features/oauth/uae_pass_details_card.dart';

/// Figma `#1a7a66` success accent (`7043:28769` / `7043:28771`) — visually
/// adjacent to `MainPalette.shade700` (`#1A7E6B`) but not an exact match, and
/// no semantic "success accent" token exists yet; a bespoke one-off like
/// this feature's other illustration colors (see `_deviceOutline` in
/// `uae_pass_device_connection_illustration.dart`).
const _successAccent = Color(0xFF1A7A66);

/// Figma `#ebebec` progress-track color (`7043:28770`) — see the same
/// constant's doc in `oauth_uae_pass_collecting_page.dart`.
const _progressTrackColor = Color(0xFFEBEBEC);

/// You're all set! (Figma `7043:28742`) — the final screen of the UAE PASS
/// flow, showing all three collected fields as complete.
///
/// UI-only for this phase (see `OAuthUaePassPage`'s class doc): there is no
/// real UAE PASS session to create yet, so "continue to Sanad" is a
/// documented no-op rather than navigating into the authenticated app —
/// doing so without a real session would either fake authentication or get
/// silently bounced back to Login by the router's own auth guard.
class OAuthUaePassSuccessPage extends StatelessWidget {
  /// Creates an [OAuthUaePassSuccessPage].
  const OAuthUaePassSuccessPage({this.details, super.key});

  /// The fields collected on the previous screen. Defaults to
  /// [UaePassCollectedDetails.placeholder] when reached without one (e.g.
  /// direct navigation during development).
  final UaePassCollectedDetails? details;

  void _continueToSanad() {
    // TODO(oauth-backend): navigate into the authenticated app once a real
    // UAE PASS session exists — no-op placeholder for this UI-only phase
    // (see class doc).
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final resolvedDetails = details ?? UaePassCollectedDetails.placeholder();

    final rows = <UaePassDetailRowData>[
      UaePassDetailRowData(
        iconAsset: AppSvgs.registrationProfile,
        label: 'oauth.uae_pass_detail_full_name_label'.tr(),
        value: resolvedDetails.fullName,
        status: UaePassDetailRowStatus.completed,
      ),
      UaePassDetailRowData(
        iconAsset: AppSvgs.uaePassVerifiedIdentity,
        label: 'oauth.uae_pass_detail_verified_identity_label'.tr(),
        value: resolvedDetails.verifiedIdentityLabel,
        status: UaePassDetailRowStatus.completed,
      ),
      UaePassDetailRowData(
        iconAsset: AppSvgs.uaePassMobileNumber,
        label: 'oauth.uae_pass_detail_mobile_number_label'.tr(),
        value: resolvedDetails.maskedMobileNumber,
        status: UaePassDetailRowStatus.completed,
      ),
    ];

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
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: responsiveDimension(AppSpacing.xxxxl)),
                      // Emphasized one-shot pop-in for the completion seal —
                      // the "you're all set" moment. Kept separate from the
                      // staggered content below so it reads as a distinct beat.
                      AppSvgPicture.asset(
                        AppSvgs.uaePassSuccessSeal,
                        width: responsiveDimension(78.3694),
                        height: responsiveDimension(79.0558),
                      ).appFadeScale(
                        context,
                        duration: AppMotionDuration.emphasis,
                        curve: AppMotionCurve.emphasizedDecelerate,
                        beginScale: 0.85,
                      ),
                      SizedBox(height: responsiveDimension(AppSpacing.xl)),
                      AppStaggeredColumn(
                        children: [
                          Text(
                            'oauth.uae_pass_success_title'.tr(),
                            textAlign: TextAlign.center,
                            style: typography.regularNone.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _successAccent,
                            ),
                          ),
                          SizedBox(height: responsiveDimension(AppSpacing.md)),
                          SizedBox(
                            width: responsiveDimension(260),
                            child: AppProgressBar(
                              value: 1,
                              height: responsiveDimension(8),
                              borderRadius: BorderRadius.circular(
                                responsiveDimension(4),
                              ),
                              trackColor: _progressTrackColor,
                              fillColor: _successAccent,
                            ),
                          ),
                          SizedBox(height: responsiveDimension(AppSpacing.xl)),
                          UaePassDetailsCard(
                            title: 'oauth.uae_pass_success_card_title'.tr(),
                            rows: rows,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AppButton(
                label: 'oauth.continue_to_sanad'.tr(),
                onPressed: _continueToSanad,
              ),
              SizedBox(height: responsiveDimension(AppSpacing.lg)),
            ],
          ),
        ),
      ),
    );
  }
}
