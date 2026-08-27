import 'package:account_settings/src/domain/enums/deletion_persona.dart';
import 'package:account_settings/src/presentation/bloc/account_deletion/account_deletion_bloc.dart';
import 'package:account_settings/src/presentation/widgets/bottom_sheets/deletion_otp_sheet.dart';
import 'package:account_settings/src/presentation/widgets/delete_confirmation_field.dart';
import 'package:account_settings/src/presentation/widgets/deletion_blockers_list.dart';
import 'package:account_settings/src/presentation/widgets/deletion_cascade_summary.dart';
import 'package:account_settings/src/presentation/widgets/deletion_warnings_list.dart';
import 'package:account_settings/src/routes/account_settings_routes.dart';
import 'package:auth/auth.dart' show AuthRoutes;
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';

/// Entry point for self-service account deletion (Account Settings →
/// Delete Account). Loads eligibility and shows the details page — blockers,
/// warnings, cascade counts, and persona are driven entirely by the server
/// response; nothing here is derived from the locally signed-in role.
///
/// Destructive flow: type `DELETE` (owners) → tap Delete → `startDeletion`
/// (idempotent `POST`) → OTP bottom sheet → verified → session ended → Login.
/// The Type-DELETE gate + Delete button *is* the confirmation — there is no
/// intermediate generic confirmation sheet. Entry always shows the details
/// page and never auto-opens the OTP sheet. If `startDeletion` returns a
/// request that no longer needs verification (already scheduled), the user is
/// routed to [AccountSettingsRoutes.deletionScheduled] instead.
class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  bool _deleteConfirmed = false;
  bool _otpSheetOpen = false;

  @override
  void initState() {
    super.initState();
    // Always load eligibility and show the details page. We deliberately do
    // NOT resume an in-flight request into the OTP sheet on entry — the first
    // screen is always the details page (an already-pending request is handled
    // via the idempotent Delete tap, not an auto-opened sheet).
    context.read<AccountDeletionBloc>().add(
      const AccountDeletionEligibilityRequested(),
    );
  }

  /// The Type-DELETE gate + this button are the confirmation — no extra
  /// confirmation sheet. `POST account/deletion` is idempotent, so this safely
  /// (re)starts or resumes a pending request.
  void _onDeletePressed() {
    context.read<AccountDeletionBloc>().add(const AccountDeletionStarted());
  }

  /// Opens the OTP bottom sheet (sharing the active bloc). By the time it
  /// resolves `true`, the bloc has already verified the OTP, scheduled the
  /// deletion, *and* ended the session (see
  /// `AccountDeletionBloc._onOtpVerified` — the same `AuthLogoutUseCase` +
  /// `SessionManager.clear()` a normal logout uses). The user leaves the
  /// deletion flow entirely and lands on Login, exactly like tapping Sign Out.
  /// Guarded so a rebuild can never open the sheet twice.
  Future<void> _openOtpSheet() async {
    if (_otpSheetOpen) return;
    _otpSheetOpen = true;
    final bloc = context.read<AccountDeletionBloc>();
    final verified = await showDeletionOtpSheet(context: context, bloc: bloc);
    _otpSheetOpen = false;
    if ((verified ?? false) && mounted) {
      context.go(AuthRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountDeletionBloc, AccountDeletionState>(
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
          onSuccess: (context, s) {
            // Start succeeded. If the (idempotent) request still needs OTP
            // verification, open the Confirm-Deletion sheet; otherwise it's
            // already scheduled — show the scheduled screen instead.
            final request = s.activeRequest;
            if (request == null || request.verificationRequired) {
              _openOtpSheet();
            } else {
              context.pushReplacement(AccountSettingsRoutes.deletionScheduled);
            }
          },
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
    if (state.eligibilityStatus == RequestStatus.loading ||
        state.eligibilityStatus == RequestStatus.initial) {
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

    // Only genuine dead-ends block the flow. An already-pending request is not
    // a dead-end — the idempotent Delete tap resumes it (see `hardBlockers`).
    if (eligibility.hasHardBlockers) {
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
          DeletionBlockersList(blockers: eligibility.hardBlockers),
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
          DeleteConfirmationField(
            onConfirmedChanged: (confirmed) =>
                setState(() => _deleteConfirmed = confirmed),
          ),
        ],
        SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'account_deletion.delete_button'.tr(),
          intent: AppButtonIntent.destructive,
          onPressed: (!isOwner || _deleteConfirmed) ? _onDeletePressed : null,
        ),
        SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'common.cancel'.tr(),
          variant: AppButtonVariant.outline,
          onPressed: () => context.pop(),
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
