import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:invitation/src/domain/entities/invitation_mock.dart';
import 'package:invitation/src/presentation/widgets/invitation_screen_shell.dart';

const _badgeSize = 72.0;
const _badgeBorderWidth = 3.0;

/// Screen 3 — Success (Figma `2560:24725`).
///
/// "Open Dashboard" has no real destination yet — it pops the whole flow so
/// the user lands back wherever they entered from (Organization Settings).
class InvitationSuccessPage extends StatelessWidget {
  const InvitationSuccessPage({
    this.invitation = InvitationMock.sample,
    super.key,
  });

  final InvitationMock invitation;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return InvitationScreenShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: responsiveDimension(_badgeSize),
                    height: responsiveDimension(_badgeSize),
                    decoration: BoxDecoration(
                      color: colors.palettes.main.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.primary,
                        width: responsiveDimension(_badgeBorderWidth),
                      ),
                    ),
                    child: Center(
                      child: AppSvgPicture.asset(
                        AppSvgs.badgeCheck,
                        width: 32,
                        height: 32,
                        colorFilter: ColorFilter.mode(
                          colors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    'invitation.success_title'.tr(),
                    style: typography.title2.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      height: 30 / 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'invitation.success_description'.tr(
                      namedArgs: {
                        'organization': invitation.organization,
                        'role': invitation.role.labelKey.tr(),
                      },
                    ),
                    style: typography.regularNormal.copyWith(
                      color: colors.textMuted,
                      height: 20 / 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          AppButton(
            label: 'invitation.open_dashboard_button'.tr(),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}
