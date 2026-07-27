import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invitation/src/domain/entities/invitation_mock.dart';
import 'package:invitation/src/presentation/widgets/invitation_screen_shell.dart';
import 'package:invitation/src/routes/invitation_routes.dart';

const _detailsCardRadius = 16.0;
const _detailsCardPadding = 20.0;

/// Screen 1 — Invitation Details (Figma `2560:24649`, frame named "Signup").
///
/// UI-only fixture: no deep link, no API, no auth. The invitation payload is
/// a mocked [InvitationMock] until the real flow lands.
class InvitationDetailsPage extends StatelessWidget {
  const InvitationDetailsPage({
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    'invitation.join_title'.tr(
                      namedArgs: {'organization': invitation.organization},
                    ),
                    style: typography.title2.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 30 / 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'invitation.join_subtitle'.tr(
                      namedArgs: {
                        'inviter': invitation.inviter,
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
                  SizedBox(height: AppSpacing.xxl),
                  _InvitationDetailsCard(invitation: invitation),
                ],
              ),
            ),
          ),
          AppButton(
            label: 'invitation.continue_button'.tr(),
            onPressed: () => context.push(
              InvitationRoutes.otp,
              extra: invitation,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitationDetailsCard extends StatelessWidget {
  const _InvitationDetailsCard({required this.invitation});

  final InvitationMock invitation;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsiveDimension(_detailsCardPadding)),
      decoration: BoxDecoration(
        color: colors.palettes.sky.shade50,
        borderRadius: BorderRadius.circular(
          responsiveDimension(_detailsCardRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'invitation.details_label'.tr().toUpperCase(),
            style: typography.smallNormal.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),

          SizedBox(height: AppSpacing.md),
          const AppDivider(),
          SizedBox(height: AppSpacing.lg),
          _DetailRow(
            label: 'invitation.detail_email'.tr(),
            value: invitation.email,
          ),
          SizedBox(height: AppSpacing.lg),
          _DetailRow(
            label: 'invitation.detail_organization'.tr(),
            value: invitation.organization,
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text(
                'invitation.detail_role'.tr(),
                style: typography.regularNormal.copyWith(
                  color: colors.textMuted,
                ),
              ),
              const Spacer(),
              AppChip(
                label: invitation.role.labelKey.tr(),
                tone: AppChipTone.softSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: typography.regularNormal.copyWith(color: colors.textMuted),
        ),
        const Spacer(),
        Flexible(
          fit: FlexFit.tight,
          flex: 2,
          child: Text(
            value,
            style: typography.regularNormal.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
