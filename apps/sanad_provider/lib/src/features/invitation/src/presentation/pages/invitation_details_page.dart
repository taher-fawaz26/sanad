import 'package:core/core.dart' show sl;
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/entities/invitation_preview_entity.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/entities/invitation_status.dart';
import 'package:sanad_provider/src/features/invitation/src/presentation/bloc/invitation_details_cubit.dart';
import 'package:sanad_provider/src/features/invitation/src/presentation/widgets/invitation_screen_shell.dart';
import 'package:sanad_provider/src/features/invitation/src/routes/invitation_routes.dart';
import 'package:sanad_provider/src/features/invitation/src/routing/invitation_route_args.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:workers/workers.dart' show WorkerType;

/// Realistic mock used only to skeletonize the real details content via
/// [AppSkeletonizer] while the token is being verified — no bespoke skeleton
/// layout.
final _skeletonPreview = InvitationPreview(
  valid: true,
  email: BoneMock.email,
  providerName: BoneMock.words(2),
  workerType: WorkerType.worker,
);

const _detailsCardRadius = 16.0;
const _detailsCardPadding = 20.0;

/// Screen 1 — Invitation Details (Figma `2560:24649`, frame named "Signup").
///
/// Calls `GET /workers/verify-token/{token}` and renders the resolved
/// [InvitationPreview] — or an invalid/expired state when the invitation
/// can no longer be accepted.
class InvitationDetailsPage extends StatelessWidget {
  const InvitationDetailsPage({required this.token, super.key});

  final String token;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<InvitationDetailsCubit>()..loadToken(token),
    child: InvitationDetailsView(token: token),
  );
}

class InvitationDetailsView extends StatelessWidget {
  const InvitationDetailsView({required this.token, super.key});

  final String token;

  @override
  Widget build(BuildContext context) {
    return InvitationScreenShell(
      child: BlocBuilder<InvitationDetailsCubit, InvitationDetailsState>(
        builder: (context, state) {
          switch (state) {
            case InvitationDetailsLoading():
              return AppSkeletonizer(
                enabled: true,
                child: _InvitationDetailsContent(
                  token: token,
                  preview: _skeletonPreview,
                ),
              );
            case InvitationDetailsFailure(:final failure):
              return _InvitationErrorView(
                message: failure.localizedMessage(),
                onRetry: () =>
                    context.read<InvitationDetailsCubit>().loadToken(token),
              );
            case InvitationDetailsInvalid(:final preview):
              return _InvitationErrorView(
                message: _invalidStatusMessage(preview.status),
              );
            case InvitationDetailsLoaded(:final preview):
              return _InvitationDetailsContent(token: token, preview: preview);
          }
        },
      ),
    );
  }

  static String _invalidStatusMessage(InvitationStatus? status) =>
      switch (status) {
        InvitationStatus.accepted => 'invitation.already_accepted'.tr(),
        InvitationStatus.expired => 'invitation.link_expired'.tr(),
        InvitationStatus.cancelled => 'invitation.link_cancelled'.tr(),
        InvitationStatus.pending || null => 'invitation.link_invalid'.tr(),
      };
}

class _InvitationErrorView extends StatelessWidget {
  const _InvitationErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: Text(
              message,
              style: typography.regularNormal.copyWith(
                color: colors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (onRetry != null)
          AppButton(label: 'invitation.retry_button'.tr(), onPressed: onRetry),
      ],
    );
  }
}

class _InvitationDetailsContent extends StatelessWidget {
  const _InvitationDetailsContent({required this.token, required this.preview});

  final String token;
  final InvitationPreview preview;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final organization = preview.providerName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'invitation.join_title'.tr(
                    namedArgs: {'organization': organization},
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
                      'organization': organization,
                      'role': _roleLabelKey(preview.workerType).tr(),
                    },
                  ),
                  style: typography.regularNormal.copyWith(
                    color: colors.textMuted,
                    height: 20 / 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xxl),
                _InvitationDetailsCard(preview: preview),
              ],
            ),
          ),
        ),
        AppButton(
          label: 'invitation.continue_button'.tr(),
          onPressed: () => context.push(
            InvitationRoutes.otp,
            extra: InvitationOtpRouteArgs(token: token, preview: preview),
          ),
        ),
      ],
    );
  }
}

/// Localization key for a worker/manager role label
/// (`invitation.role_worker` / `invitation.role_manager`).
String _roleLabelKey(WorkerType? type) => switch (type) {
  WorkerType.manager => 'invitation.role_manager',
  WorkerType.worker || null => 'invitation.role_worker',
};

class _InvitationDetailsCard extends StatelessWidget {
  const _InvitationDetailsCard({required this.preview});

  final InvitationPreview preview;

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
            value: preview.email ?? '',
          ),
          SizedBox(height: AppSpacing.lg),
          _DetailRow(
            label: 'invitation.detail_organization'.tr(),
            value: preview.providerName ?? '',
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
                label: _roleLabelKey(preview.workerType).tr(),
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
