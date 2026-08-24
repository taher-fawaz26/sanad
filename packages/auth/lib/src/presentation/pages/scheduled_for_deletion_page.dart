import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shown when `login/verify` (or `social/login`) reports
/// `status: SCHEDULED_FOR_DELETION` — no tokens exist, so there is nothing
/// to do but explain the state and offer a way back to the login screen.
///
/// This is the real terminal lockout: deletion has moved past the grace
/// period into actual execution. Sign-in during the grace period itself
/// auto-cancels deletion server-side and returns a normal `ACTIVE` session
/// instead, so this screen is never reached for a recoverable account.
class ScheduledForDeletionPage extends StatelessWidget {
  const ScheduledForDeletionPage({required this.onLoggedOut, super.key});

  final VoidCallback onLoggedOut;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLogoutSuccessState) onLoggedOut();
      },
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(responsiveDimension(AppSpacing.lg)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'auth.account_scheduled_for_deletion_title'.tr(),
                  textAlign: TextAlign.center,
                  style: context.appTypography.title2,
                ),
                SizedBox(height: responsiveDimension(AppSpacing.sm)),
                Text(
                  'auth.account_scheduled_for_deletion_description'.tr(),
                  textAlign: TextAlign.center,
                  style: context.appTypography.regularNormal,
                ),
                SizedBox(height: responsiveDimension(AppSpacing.xl)),
                AppButton(
                  label: 'auth.logout'.tr(),
                  onPressed: () =>
                      context.read<AuthBloc>().add(AuthLogoutEvent()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
