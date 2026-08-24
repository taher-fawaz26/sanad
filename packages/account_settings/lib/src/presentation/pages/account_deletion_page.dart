import 'package:account_settings/src/domain/enums/account_deletion_status.dart';
import 'package:account_settings/src/domain/enums/deletion_persona.dart';
import 'package:account_settings/src/presentation/bloc/account_deletion/account_deletion_bloc.dart';
import 'package:account_settings/src/presentation/widgets/business_name_confirm_field.dart';
import 'package:account_settings/src/presentation/widgets/deletion_blockers_list.dart';
import 'package:account_settings/src/presentation/widgets/deletion_cascade_summary.dart';
import 'package:account_settings/src/presentation/widgets/deletion_warnings_list.dart';
import 'package:account_settings/src/routes/account_settings_routes.dart';
import 'package:auth/auth.dart' show SessionManager;
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';

/// Entry point for self-service account deletion (Account Settings →
/// Delete Account). Loads the active request first (resume path), then
/// falls back to eligibility for a fresh request. Every branch — blockers,
/// warnings, cascade counts, persona — is driven entirely by the server
/// response; nothing here is derived from the locally signed-in role.
class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  bool _businessNameConfirmed = false;

  @override
  void initState() {
    super.initState();
    context.read<AccountDeletionBloc>().add(
      const AccountDeletionStatusRequested(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountDeletionBloc, AccountDeletionState>(
      listenWhen: (previous, current) =>
          previous.activeRequestStatus != current.activeRequestStatus,
      listener: (context, state) {
        if (state.activeRequestStatus != RequestStatus.success) return;
        final request = state.activeRequest;
        if (request == null) {
          context.read<AccountDeletionBloc>().add(
            const AccountDeletionEligibilityRequested(),
          );
          return;
        }
        switch (request.status) {
          case AccountDeletionStatus.pendingVerification:
            context.pushReplacement(AccountSettingsRoutes.deletionOtp);
          case AccountDeletionStatus.scheduled:
          case AccountDeletionStatus.executing:
            context.pushReplacement(AccountSettingsRoutes.deletionScheduled);
          case AccountDeletionStatus.completed:
          case AccountDeletionStatus.cancelled:
          case AccountDeletionStatus.failed:
          case AccountDeletionStatus.restored:
          case AccountDeletionStatus.unknown:
            context.read<AccountDeletionBloc>().add(
              const AccountDeletionEligibilityRequested(),
            );
        }
      },
      builder: (context, state) {
        return MutationListener<AccountDeletionBloc, AccountDeletionState>(
          status: (s) => s.mutationStatus,
          title: (context) => 'account_deletion.starting_title'.tr(),
          onFailure: (context, s) {
            if (s.mutationFailure != null) {
              showAppErrorSnackbar(
                context: context,
                title: s.mutationFailure!.localizedMessage(),
              );
            }
          },
          onSuccess: (context, s) =>
              context.pushReplacement(AccountSettingsRoutes.deletionOtp),
          child: AppScrollPage(
            slivers: [
              AppSliverAppBar(
                navBar: AppNavBar(
                  title: 'account_deletion.title'.tr(),
                  showBackButton: true,
                  onLeadingTap: () => context.pop(),
                ),
              ),
              AppSliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                sliver: SliverToBoxAdapter(child: _buildBody(context, state)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AccountDeletionState state) {
    final isLoading =
        state.activeRequestStatus == RequestStatus.loading ||
        state.eligibilityStatus == RequestStatus.loading;
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.appColors.primary),
      );
    }

    if (state.eligibilityStatus == RequestStatus.failure) {
      return AppAlert(
        message:
            state.eligibilityFailure?.localizedMessage() ??
            'errors.unknown'.tr(),
        type: AppAlertType.error,
      );
    }

    final eligibility = state.eligibility;
    if (eligibility == null) return const SizedBox.shrink();

    if (eligibility.hasBlockers) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'account_deletion.blocked_title'.tr(),
            style: context.appTypography.title3.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          DeletionBlockersList(blockers: eligibility.blockers),
        ],
      );
    }

    final cascade = eligibility.cascadePreview;
    final isOwner = cascade.isOrganizationOwner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'account_deletion.confirm_title'.tr(),
          style: context.appTypography.title3.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          _descriptionFor(cascade.persona, eligibility.gracePeriodDays),
          style: context.appTypography.regularNormal.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        if (cascade.persona == DeletionPersona.manager) ...[
          SizedBox(height: AppSpacing.md),
          AppAlert(
            message: 'account_deletion.manager_org_unaffected'.tr(),
            type: AppAlertType.info,
          ),
        ],
        if (eligibility.hasWarnings) ...[
          SizedBox(height: AppSpacing.md),
          DeletionWarningsList(warnings: eligibility.warnings),
        ],
        if (isOwner) ...[
          SizedBox(height: AppSpacing.lg),
          DeletionCascadeSummary(cascade: cascade),
          SizedBox(height: AppSpacing.lg),
          BusinessNameConfirmField(
            businessName: sl<SessionManager>().businessName ?? '',
            onConfirmedChanged: (confirmed) =>
                setState(() => _businessNameConfirmed = confirmed),
          ),
        ],
        SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'account_deletion.delete_button'.tr(),
          destructive: true,
          onPressed: (!isOwner || _businessNameConfirmed)
              ? () => context.read<AccountDeletionBloc>().add(
                  const AccountDeletionStarted(),
                )
              : null,
        ),
      ],
    );
  }

  String _descriptionFor(DeletionPersona persona, int gracePeriodDays) {
    final key = switch (persona) {
      DeletionPersona.companyProvider =>
        'account_deletion.confirm_description_owner',
      DeletionPersona.worker => 'account_deletion.confirm_description_worker',
      DeletionPersona.manager => 'account_deletion.confirm_description_manager',
      _ => 'account_deletion.confirm_description_default',
    };
    return key.tr(namedArgs: {'days': '$gracePeriodDays'});
  }
}
