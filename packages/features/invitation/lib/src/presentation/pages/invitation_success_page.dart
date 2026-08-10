import 'package:app_assets/app_assets.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:invitation/src/presentation/widgets/invitation_screen_shell.dart';
import 'package:invitation/src/routing/invitation_route_args.dart';
import 'package:workers/workers.dart' show WorkerType;

const _badgeSize = 72.0;
const _badgeBorderWidth = 3.0;

/// Screen 3 — Success (Figma `2560:24725`).
///
/// Reflects the real accepted session: [InvitationSuccessRouteArgs.preview]
/// supplies the organization/role copy (already known from verify-token),
/// and [InvitationSuccessRouteArgs.session] is the freshly persisted
/// `AuthSessionEntity` from `accept` — used here for the worker's own name
/// when the profile carries one.
///
/// "Open Dashboard" has no real destination yet — it pops the whole flow so
/// the user lands back wherever they entered from. Wiring this to an actual
/// dashboard route is deferred to the deep-link follow-up (see
/// `InvitationModule` doc comment): today's route always opens from within
/// an app shell that has no "invitation" entry point of its own yet.
class InvitationSuccessPage extends StatelessWidget {
  const InvitationSuccessPage({required this.args, super.key});

  final InvitationSuccessRouteArgs args;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final organization = args.preview.providerName ?? '';
    final roleKey = switch (args.preview.workerType) {
      WorkerType.manager => 'invitation.role_manager',
      WorkerType.worker || null => 'invitation.role_worker',
    };
    final workerName = switch (args.session.profile) {
      WorkerProfileModel(:final name) => name,
      _ => null,
    };

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
                        'organization': organization,
                        'role': roleKey.tr(),
                      },
                    ),
                    style: typography.regularNormal.copyWith(
                      color: colors.textMuted,
                      height: 20 / 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (workerName != null && workerName.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'invitation.success_welcome'.tr(
                        namedArgs: {'name': workerName},
                      ),
                      style: typography.regularNormal.copyWith(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w600,
                        height: 20 / 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
