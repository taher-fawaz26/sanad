import 'package:account_settings/src/domain/enums/preferred_language.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:account_settings/src/presentation/bloc/account_settings/account_settings_bloc.dart';
import 'package:account_settings/src/presentation/widgets/bottom_sheets/add_or_change_owner_email_sheet.dart';
import 'package:account_settings/src/presentation/widgets/bottom_sheets/add_or_change_owner_phone_sheet.dart';
import 'package:account_settings/src/presentation/widgets/bottom_sheets/edit_name_sheet.dart';
import 'package:account_settings/src/presentation/widgets/bottom_sheets/language_preferences_bottom_sheet.dart';
import 'package:account_settings/src/presentation/widgets/sections/account_credentials_section.dart';
import 'package:account_settings/src/presentation/widgets/sections/help_support_section.dart';
import 'package:account_settings/src/presentation/widgets/sections/language_preferences_section.dart';
import 'package:app_assets/app_assets.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';

/// Account settings hub — Figma `3821:18875`.
///
/// Shared by provider and client. Composes credential, language, help, and
/// delete-account flows from existing design-system widgets.
class AccountSettingsPage extends StatelessWidget {
  /// Creates the account settings page.
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionManager = sl<SessionManager>();
    // Identity (user, isEmailVerified) is sourced from SessionManager — the
    // durable single source of truth — rather than the shared app-wide
    // AuthBloc's transient state. AuthBloc is scoped to the whole app shell,
    // so its last-emitted state may belong to an unrelated screen (e.g. an
    // in-flight AuthOtpSentState) by the time this page builds; SessionManager
    // always reflects the actual signed-in session.
    return ValueListenableBuilder<AuthSessionEntity?>(
      valueListenable: sessionManager.watch(),
      builder: (context, session, _) {
        return BlocConsumer<AuthBloc, AuthState>(
          // AppProgress.show/dismiss are idempotent, so it's safe to
          // evaluate on every AuthBloc emission rather than narrowing
          // listenWhen to specific states.
          listener: (context, state) {
            if (state is AuthLogoutLoadingState) {
              AppProgress.show(
                context,
                title: 'settings.logging_out_title'.tr(),
              );
              return;
            }
            if (state is AuthDeleteAccountLoadingState) {
              AppProgress.show(
                context,
                title: 'settings.deleting_account_title'.tr(),
              );
              return;
            }
            AppProgress.dismiss();
            if (state is AuthLogoutSuccessState) {
              context.go(AuthRoutes.login);
              return;
            }
            if (state is AuthDeleteAccountFailureState) {
              showAppErrorSnackbar(
                context: context,
                title: state.failure.message,
              );
            }
          },
          builder: (context, authState) {
            return BlocBuilder<AccountSettingsBloc, AccountSettingsState>(
              builder: (context, accountState) {
                // Only true on a first-ever open before the session has any
                // account-settings snapshot (e.g. a persona whose session
                // predates the persona-profile refresh) — never a blanket
                // loading flag, so the background refresh never wipes
                // already-visible content.
                final isInitialLoad = accountState.settings == null;

                final email = accountState.email ?? session?.user.email;

                return MutationListener<AccountSettingsBloc,
                    AccountSettingsState>(
                  status: (state) => state.saveStatus,
                  title: (context) => 'settings.saving_title'.tr(),
                  onFailure: (context, state) {
                    if (state.saveFailure != null) {
                      showAppErrorSnackbar(
                        context: context,
                        title: state.saveFailure!.message,
                      );
                    }
                  },
                  onSuccess: (context, state) async {
                    if (state.preferredLanguage != null) {
                      await _applyPreferredLanguage(
                        context,
                        state.preferredLanguage!,
                      );
                    }
                  },
                  child: AppScrollPage(
                    slivers: [
                      AppSliverAppBar(
                        navBar: AppNavBar(
                          title: 'settings.account_settings'.tr(),
                          showBackButton: true,
                          onLeadingTap: () => context.pop(),
                        ),
                      ),
                      AppSliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                        sliver: AppSkeletonizer.sliver(
                          enabled: isInitialLoad,
                          child: SliverMainAxisGroup(
                            slivers: [
                              AppSliverBox(
                                child: AccountCredentialsSection(
                                  name: accountState.name,
                                  phone: accountState.phone,
                                  email: email,
                                  emailVerified:
                                      session?.isEmailVerified ?? false,
                                  onAddPhone: () =>
                                      _addOrChangePhone(context, null),
                                  onChangePhone: () => _addOrChangePhone(
                                    context,
                                    accountState.phone,
                                  ),
                                  onAddEmail: () =>
                                      _addOrChangeEmail(context, null),
                                  onChangeEmail: () =>
                                      _addOrChangeEmail(context, email),
                                  onEditName: () => _editName(
                                    context,
                                    accountState.name,
                                  ),
                                ),
                              ),
                              AppSliverGap(AppSpacing.lg),
                              AppSliverBox(
                                child: LanguagePreferencesSection(
                                  selectedLanguageLabel: _languageLabel(
                                    accountState.preferredLanguage?.toApi(),
                                  ),
                                  onTap: () => _openLanguageSheet(context),
                                ),
                              ),
                              AppSliverGap(AppSpacing.lg),
                              AppSliverBox(
                                child: HelpSupportSection(
                                  onContactSupport: () =>
                                      _showComingSoon(context),
                                  onTermsOfService: () =>
                                      _showComingSoon(context),
                                  onPrivacyPolicy: () =>
                                      _showComingSoon(context),
                                ),
                              ),
                              AppSliverGap(AppSpacing.lg),
                              AppSliverBox(
                                child: _DeleteAccountRow(
                                  onTap: session == null
                                      ? null
                                      : () => _confirmDeleteAccount(
                                          context,
                                          session.user,
                                        ),
                                ),
                              ),
                              AppSliverGap(AppSpacing.lg),
                              AppSliverBox(
                                child: AppButton(
                                  label: 'settings.logout'.tr(),
                                  onPressed: () => context.read<AuthBloc>().add(
                                    AuthLogoutEvent(),
                                  ),
                                ),
                              ),
                              AppSliverGap(AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _languageLabel(String? code) {
    if (code == 'en') return 'app.english'.tr();
    if (code == 'ar') return 'app.arabic'.tr();
    return 'app.english'.tr();
  }

  Future<void> _openLanguageSheet(BuildContext context) async {
    final accountBloc = context.read<AccountSettingsBloc>();
    final currentCode =
        accountBloc.state.preferredLanguage?.toApi() ??
        context.read<TranslateBloc>().state.languageCode;

    final result = await showLanguagePreferencesBottomSheet(
      context: context,
      initialLanguageCode: currentCode,
    );
    if (result == null || !context.mounted) return;
    if (result == currentCode) return;

    accountBloc.add(
      AccountSettingsUpdated(
        UpdateAccountSettingsParams(
          preferredLanguage: PreferredLanguage.fromApi(result),
        ),
      ),
    );
  }

  Future<void> _applyPreferredLanguage(
    BuildContext context,
    PreferredLanguage language,
  ) async {
    final code = language.toApi();
    final locale = code == 'en'
        ? const Locale('en', 'US')
        : const Locale('ar', 'AR');

    await context.setLocale(locale);
    if (!context.mounted) return;

    context.read<TranslateBloc>().add(
      code == 'ar' ? TrArabicEvent() : TrEnglishEvent(),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    UserEntity user,
  ) async {
    final confirmed = await showAppPopover<bool>(
      context: context,
      title: 'settings.delete_account'.tr(),
      description: 'settings.delete_account_confirm_description'.tr(),
      imageLayout: AppDialogImageLayout.iconSmall,
      featureIconColor: AppFeatureIconColor.error,
      featureIconSize: AppFeatureIconSize.lg,
      featureIconTheme: AppFeatureIconTheme.lightCircleOutline,
      actions: AppPopoverActions.dual,
      primaryLabel: 'common.delete'.tr(),
      primaryDestructive: true,
      secondaryLabel: 'common.cancel'.tr(),
      onPrimary: () => Navigator.of(context, rootNavigator: true).pop(true),
      onSecondary: () => Navigator.of(context, rootNavigator: true).pop(false),
    );

    if (confirmed ?? false) {
      if (!context.mounted) return;
      context.read<AuthBloc>().add(AuthDeleteAccountEvent(user.id));
    }
  }

  Future<void> _editName(BuildContext context, String? currentName) async {
    final result = await showEditNameSheet(
      context: context,
      initialName: currentName,
    );
    if (result == null || !context.mounted || result == currentName) return;

    context.read<AccountSettingsBloc>().add(
      AccountSettingsUpdated(UpdateAccountSettingsParams(name: result)),
    );
  }

  Future<void> _addOrChangePhone(
    BuildContext context,
    String? currentPhone,
  ) async {
    final result = await showAddOrChangeOwnerPhoneSheet(
      context: context,
      initialPhone: currentPhone,
    );
    if (result == null || !context.mounted) return;
    await sl<SessionManager>().setPhone(result);
    if (!context.mounted) return;
    context.read<AccountSettingsBloc>().add(const AccountSettingsRefreshed());
  }

  Future<void> _addOrChangeEmail(
    BuildContext context,
    String? currentEmail,
  ) async {
    final result = await showAddOrChangeOwnerEmailSheet(
      context: context,
      initialEmail: currentEmail,
    );
    if (result == null || !context.mounted) return;
    await sl<SessionManager>().setEmail(result);
    if (!context.mounted) return;
    context.read<AccountSettingsBloc>().add(const AccountSettingsRefreshed());
  }

  void _showComingSoon(BuildContext context) {
    showAppSnackbar(
      context: context,
      title: 'settings.coming_soon'.tr(),
    );
  }
}

class _DeleteAccountRow extends StatelessWidget {
  const _DeleteAccountRow({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 18,
          ),
          child: Row(
            children: [
              AppSvgPicture.asset(
                AppSvgs.trashBold,
                width: 24,
                height: 24,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'settings.delete_account'.tr(),
                  style: typography.regularNormal.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
