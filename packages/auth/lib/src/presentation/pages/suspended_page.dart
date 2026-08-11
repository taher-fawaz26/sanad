import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shown when the account is suspended (`login/verify` /
/// `social/login` → `status: SUSPENDED`) — no tokens exist, so there is
/// nothing to do but explain the state and offer a way back to the login
/// screen.
///
/// Deliberately minimal — a placeholder per the plan's open product
/// question on the exact SUSPENDED UX (support contact, etc.); the state
/// machine correctness (no crash, no silent auth) is what's in scope here.
class SuspendedPage extends StatelessWidget {
  const SuspendedPage({required this.onLoggedOut, super.key});

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
                  'auth.account_suspended_title'.tr(),
                  textAlign: TextAlign.center,
                  style: context.appTypography.title2,
                ),
                SizedBox(height: responsiveDimension(AppSpacing.sm)),
                Text(
                  'auth.account_suspended_description'.tr(),
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
