import 'package:account_settings/account_settings.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:notifications/notifications.dart';
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
                // `AppGenericEmptyState`'s illustration is a shuttered shop
                // — right for "no requests", wrong for a person's own profile
                // (A-16). No profile-shaped asset exists in `app_assets`, so
                // this uses the same component with a neutral glyph rather
                // than shipping a picture that says the wrong thing.
                AppEmptyState(
                  illustration: Icon(
                    Icons.person_outline_rounded,
                    size: AppDimension.iconButtonLg,
                    color: context.appColors.textMuted,
                  ),
                  title: 'profile.empty_title'.tr(),
                  description: 'profile.empty_description'.tr(),
                ),
                SizedBox(height: AppSpacing.xl),
                // This page's real destinations.
                AppGroupedKeyValueList(
                  items: [
                    // The notification inbox.
                    //
                    // **Temporary placement.** It used to be a bell in the
                    // Home shell's header, which Figma's header does not
                    // draw; for this phase it lives here, in the same
                    // grouped list as Account Settings, so the inbox keeps an
                    // entry point while the final location is decided. This
                    // is a *navigation* change only — the route
                    // (`NotificationsRoutes.notifications`), the screen, the
                    // FCM handling and the deep links are untouched, and
                    // moving it again is one row.
                    GroupedKeyValueItem(
                      title: 'notifications.title'.tr(),
                      value: '',
                      onTap: () =>
                          context.push(NotificationsRoutes.notifications),
                    ),
                    // The account settings hub — language, and account
                    // deletion — was registered and routable but reachable
                    // from nowhere (C-11).
                    GroupedKeyValueItem(
                      title: 'settings.account_settings'.tr(),
                      value: '',
                      onTap: () => context.push(AccountSettingsRoutes.hub),
                    ),
                  ],
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
