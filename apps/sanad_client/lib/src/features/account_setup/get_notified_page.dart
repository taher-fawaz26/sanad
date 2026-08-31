import 'dart:ui';

import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/routing/client_routes.dart';

/// "Get Notified" (Figma `7002:27677`) — the final post-authentication setup
/// screen, reached after Enter Name for both the Email and Phone flows (one
/// shared screen, not duplicated per channel).
///
/// Both `Turn On Notifications` and `Skip` complete setup by entering the
/// authenticated app (`ClientRoutes.home`). Notification enablement itself is
/// intentionally out of scope for this task: neither action requests real OS
/// permission or registers a push token — that lands with the notifications
/// feature. The session was already established at OTP verify, so this screen
/// only closes the setup flow.
class GetNotifiedPage extends StatelessWidget {
  /// Creates a [GetNotifiedPage].
  const GetNotifiedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Scaffold(
      appBar: AppNavBar(
        title: '',
        showBackButton: true,
        onLeadingTap: () => context.pop(),
        trailingAction: AppNavBarTrailingAction.text,
        trailingLabel: 'common.skip'.tr(),
        onTrailingTap: () => context.go(ClientRoutes.home),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: responsiveDimension(AppSpacing.xxxxl)),
                      Container(
                        width: responsiveDimension(56),
                        height: responsiveDimension(56),
                        decoration: BoxDecoration(
                          color: colors.palettes.sky.shade100,
                          borderRadius: AppRadius.circularXl,
                        ),
                        child: Center(
                          child: AppSvgPicture.asset(
                            AppSvgs.notification,
                            width: responsiveDimension(AppDimension.iconMenu),
                            height: responsiveDimension(
                              AppDimension.iconMenu,
                            ),
                            colorFilter: ColorFilter.mode(
                              colors.palettes.sky.shade700,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: responsiveDimension(AppSpacing.xxl)),
                      Text(
                        'get_notified.title'.tr(),
                        style: typography.title3.copyWith(
                          fontSize: 28.rfs,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: responsiveDimension(AppSpacing.sm)),
                      Text(
                        'get_notified.subtitle'.tr(),
                        style: typography.regularNormal.copyWith(
                          fontSize: 16.rfs,
                          height: 1.4,
                          color: _GetNotifiedTokens.subtitleColor,
                        ),
                      ),
                      SizedBox(height: responsiveDimension(AppSpacing.xxl)),
                      const _NotificationIllustration(),
                    ],
                  ),
                ),
              ),
              AppPageEntrance(
                distance: 10,
                child: AppButton(
                  label: 'get_notified.turn_on_button'.tr(),
                  onPressed: () => context.go(ClientRoutes.home),
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.sm)),
              // The outer Column is crossAxisAlignment.start (for the
              // icon/title above), so a bare Text sizes to its own content
              // and textAlign.center has nothing to center within —
              // SizedBox(width: infinity) gives it the full row to center
              // in, matching AppButton's own always-full-width behavior.
              SizedBox(
                width: double.infinity,
                child: Text(
                  'get_notified.helper_text'.tr(),
                  textAlign: TextAlign.center,
                  style: typography.smallNormal.copyWith(
                    fontSize: 12.rfs,
                    height: 16 / 12,
                    color: _GetNotifiedTokens.helperTextColor,
                  ),
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.lg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Colors this frame specifies that don't bind to any current design-system
/// token (confirmed via `get_variable_defs` — neither is a named Figma
/// variable either, unlike the icon's `sky/700`/`sky/100`).
abstract final class _GetNotifiedTokens {
  static const subtitleColor = Color(0xFF5C6470);
  static const cardBodyColor = Color(0xFF6B7280);

  /// Figma `Text Color/text-grey` — same legacy variable as the OTP
  /// screen's countdown caption (`otp_view.dart`'s `_countdownColor`); no
  /// design-system token matches it either.
  static const helperTextColor = Color(0xFF9EA2AE);
}

/// The three-card notification preview (Figma `7000:25415`), backed by a
/// soft rounded panel with a faint green/lime glow behind it.
///
/// The glow is a decorative approximation, not pixel-identical to Figma's
/// two absolutely-positioned, rotated blur blobs — those coordinates were
/// computed for one fixed canvas size and would clip or misplace on the
/// smaller/larger/keyboard-open layouts this screen must also support (see
/// `.claude/rules/ui.md` responsive guidance). The cards themselves
/// (copy, spacing, avatar, colors) are exact.
class _NotificationIllustration extends StatelessWidget {
  const _NotificationIllustration();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(responsiveDimension(32)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: responsiveDimension(16),
          vertical: responsiveDimension(24),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFECEEEF).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(responsiveDimension(32)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -responsiveDimension(40),
              left: -responsiveDimension(30),
              child: _blurBlob(const Color(0xFF48FFB7), 170),
            ),
            Positioned(
              bottom: -responsiveDimension(50),
              right: -responsiveDimension(20),
              child: _blurBlob(const Color(0xFFBBFF44), 150),
            ),
            Column(
              children: [
                _NotificationCard(
                  title: 'get_notified.preview_document_title'.tr(),
                  body: 'get_notified.preview_document_body'.tr(),
                  time: 'get_notified.preview_document_time'.tr(),
                ),
                SizedBox(height: responsiveDimension(AppSpacing.md)),
                _NotificationCard(
                  title: 'get_notified.preview_offer_title'.tr(),
                  body: 'get_notified.preview_offer_body'.tr(),
                  time: 'get_notified.preview_offer_time'.tr(),
                ),
                SizedBox(height: responsiveDimension(AppSpacing.md)),
                _NotificationCard(
                  title: 'get_notified.preview_id_title'.tr(),
                  body: 'get_notified.preview_id_body'.tr(),
                  time: 'get_notified.preview_id_time'.tr(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurBlob(Color color, double size) {
    final dimension = responsiveDimension(size);
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: Container(
        width: dimension,
        height: dimension,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.title,
    required this.body,
    required this.time,
  });

  final String title;
  final String body;
  final String time;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsiveDimension(16),
        vertical: responsiveDimension(12),
      ),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(responsiveDimension(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: responsiveDimension(6),
            offset: Offset(0, responsiveDimension(4)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: responsiveDimension(36),
            height: responsiveDimension(36),
            decoration: const BoxDecoration(
              color: Color(0xFFFBFFFD),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppSvgPicture.asset(
                AppSvgs.uaePassDeviceSparkle,
                width: responsiveDimension(22),
                height: responsiveDimension(22),
              ),
            ),
          ),
          SizedBox(width: responsiveDimension(AppSpacing.sm)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.regularNormal.copyWith(
                    fontSize: 15.rfs,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.regularNormal.copyWith(
                    fontSize: 14.rfs,
                    color: _GetNotifiedTokens.cardBodyColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsiveDimension(AppSpacing.sm)),
          // Bounded so a longer-than-expected value (a locale whose "2h"
          // equivalent is wordier, or — as this package's own tests run
          // with no EasyLocalization bootstrap — a raw fallback key) can
          // never eat into the title/body column's space; real timestamps
          // are always short, so this never visibly clips them.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsiveDimension(48)),
            child: Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.tinyNormal.copyWith(
                fontSize: 12.rfs,
                color: _GetNotifiedTokens.cardBodyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
