import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Account settings hub — shared by provider and client.
///
/// Logout lives here (moved from the organization KPI hub). Future account
/// screens (profile, security, …) will be added as placeholders later.
class AccountSettingsPage extends StatelessWidget {
  /// Creates the account settings hub.
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLogoutSuccessState) {
          context.go(AuthRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppNavBar(
          title: 'settings.account_settings'.tr(),
          showBackButton: true,
          onLeadingTap: () => context.pop(),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: AppGenericEmptyState(
                  title: 'settings.placeholder_title'.tr(),
                  description: 'settings.placeholder_description'.tr(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: AppButton(
                label: 'settings.logout'.tr(),
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthLogoutEvent()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
