import 'package:account_settings/src/domain/enums/account_deletion_status.dart';
import 'package:account_settings/src/presentation/bloc/account_deletion/account_deletion_bloc.dart';
import 'package:account_settings/src/routes/account_settings_routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';

/// Shows the scheduled/executing deletion state and offers the in-app
/// cancel (`DELETE account/deletion`) while the request is still
/// cancellable. Reached after OTP verification, or directly when resuming
/// an already-scheduled request.
class DeletionScheduledPage extends StatefulWidget {
  const DeletionScheduledPage({super.key});

  @override
  State<DeletionScheduledPage> createState() => _DeletionScheduledPageState();
}

class _DeletionScheduledPageState extends State<DeletionScheduledPage> {
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
          previous.mutationStatus != current.mutationStatus,
      listener: (context, state) {},
      builder: (context, state) {
        final request = state.activeRequest;
        final colors = context.appColors;
        final typography = context.appTypography;

        return MutationListener<AccountDeletionBloc, AccountDeletionState>(
          status: (s) => s.mutationStatus,
          title: (context) => 'account_deletion.cancelling_title'.tr(),
          onFailure: (context, s) {
            if (s.mutationFailure != null) {
              showAppErrorSnackbar(
                context: context,
                title: s.mutationFailure!.localizedMessage(),
              );
            }
          },
          onSuccess: (context, s) {
            showAppSnackbar(
              context: context,
              title: 'account_deletion.cancelled_success'.tr(),
              color: AppSnackbarColor.primary,
            );
            context.go(AccountSettingsRoutes.hub);
          },
          child: AppScrollPage(
            slivers: [
              AppSliverAppBar(
                navBar: AppNavBar(
                  title: 'account_deletion.scheduled_title'.tr(),
                  showBackButton: true,
                  onLeadingTap: () => context.go(AccountSettingsRoutes.hub),
                ),
              ),
              AppSliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: state.activeRequestStatus == RequestStatus.loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: colors.primary,
                          ),
                        )
                      : request == null
                      ? Text(
                          'account_deletion.scheduled_no_active_request'.tr(),
                          style: typography.regularNormal.copyWith(
                            color: colors.textSecondary,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              request.status == AccountDeletionStatus.executing
                                  ? 'account_deletion.executing_description'
                                        .tr()
                                  : 'account_deletion.scheduled_description'.tr(
                                      namedArgs: {
                                        'date': _formatDate(
                                          request.scheduledExecutionDate,
                                        ),
                                      },
                                    ),
                              style: typography.regularNormal.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xl),
                            if (request.isCancellable)
                              AppButton(
                                label: 'account_deletion.cancel_deletion_button'
                                    .tr(),
                                onPressed: () =>
                                    context.read<AccountDeletionBloc>().add(
                                      const AccountDeletionCancelled(),
                                    ),
                              )
                            else
                              AppAlert(
                                message:
                                    'account_deletion.executing_non_cancellable'
                                        .tr(),
                                type: AppAlertType.error,
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat.yMMMMd().format(date);
  }
}
