import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

/// Page for viewing and editing the client profile.
class ClientProfilePage extends StatelessWidget {
  /// Creates a [ClientProfilePage].
  const ClientProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLogoutLoadingState) {
            AppProgress.show(
              context,
              title: 'settings.logging_out_title'.tr(),
            );
            return;
          }
          AppProgress.dismiss();
          if (state is AuthLogoutSuccessState) {
            context.go(AuthRoutes.login);
          }
        },
        child: Scaffold(
          appBar: AppNavBar(
            title: 'profile.title'.tr(),
            showBackButton: true,
            onLeadingTap: () => context.pop(),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              children: [
                AppGenericEmptyState(
                  title: 'profile.empty_title'.tr(),
                  description: 'profile.empty_description'.tr(),
                ),
                SizedBox(height: AppSpacing.xl),
                Builder(
                  builder: (context) => AppButton(
                    label: 'settings.logout'.tr(),
                    onPressed: () => context.read<AuthBloc>().add(
                          AuthLogoutEvent(),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
