import 'package:account_settings/src/domain/enums/preferred_language.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:account_settings/src/presentation/bloc/account_settings/account_settings_bloc.dart';
import 'package:account_settings/src/presentation/bloc/security/security_bloc.dart';
import 'package:account_settings/src/presentation/widgets/bottom_sheets/add_or_change_owner_email_sheet.dart';
import 'package:account_settings/src/presentation/widgets/bottom_sheets/add_or_change_owner_phone_sheet.dart';
import 'package:account_settings/src/presentation/widgets/bottom_sheets/edit_name_sheet.dart';
import 'package:account_settings/src/presentation/widgets/bottom_sheets/language_preferences_bottom_sheet.dart';
import 'package:account_settings/src/presentation/widgets/sections/account_credentials_section.dart';
import 'package:account_settings/src/presentation/widgets/sections/help_support_section.dart';
import 'package:account_settings/src/presentation/widgets/sections/language_preferences_section.dart';
import 'package:account_settings/src/presentation/widgets/sections/security_section.dart';
import 'package:account_settings/src/routes/account_settings_routes.dart';
import 'package:app_assets/app_assets.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:device/device.dart';
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
            AppProgress.dismiss();
            if (state is AuthLogoutSuccessState) {
              context.go(AuthRoutes.login);
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

                return MutationListener<
                  AccountSettingsBloc,
                  AccountSettingsState
                >(
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
                              const AppSliverBox(child: _SecuritySliver()),
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
                                      : () => context.push(
                                          AccountSettingsRoutes.deletion,
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

/// Security section, wired to its own bloc.
///
/// Scoped to its own [BlocBuilder] so an in-flight biometric prompt repaints
/// this row only, and never the rest of the settings page.
///
/// `SecuritySection` resolves its labels with `.tr()`, which reads the active
/// locale at build time but does *not* subscribe the widget to locale changes.
/// This sliver is intentionally `const`, so it is never rebuilt by an ancestor
/// repaint on a language switch — that is why the row alone used to stay in the
/// previous language until the page was re-entered. The inner
/// `BlocBuilder<TranslateBloc>` fixes that at the root: [TranslateBloc] is the
/// app-wide source of truth for language and emits a new state on every
/// switch, so this self-subscribing builder rebuilds `SecuritySection`
/// (re-running its `.tr()` lookups) immediately, without touching
/// [SecurityBloc] — the biometric capability/lock/loading state is preserved
/// across the locale change.
class _SecuritySliver extends StatelessWidget {
  const _SecuritySliver();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SecurityBloc, SecurityState>(
      listenWhen: (previous, current) =>
          previous.toggleStatus != current.toggleStatus,
      listener: (context, state) {
        if (state.toggleStatus == RequestStatus.failure) {
          showAppErrorSnackbar(
            context: context,
            title: switch (state.lastFailure) {
              BiometricAuthStatus.lockedOut =>
                'settings.biometric_error_locked_out'.tr(),
              BiometricAuthStatus.notAvailable ||
              BiometricAuthStatus.notEnrolled ||
              BiometricAuthStatus.passcodeNotSet =>
                'settings.biometric_error_not_available'.tr(),
              _ => 'settings.biometric_error_generic'.tr(),
            },
          );
          return;
        }
        if (state.toggleStatus == RequestStatus.success) {
          showAppSnackbar(
            context: context,
            title: state.enabled
                ? 'settings.app_lock_enabled_message'.tr()
                : 'settings.app_lock_disabled_message'.tr(),
          );
        }
      },
      builder: (context, state) {
        // Rebuild the localized labels when the app language changes, keeping
        // the biometric state (`state`) from SecurityBloc untouched.
        return BlocBuilder<TranslateBloc, TranslateState>(
          builder: (context, _) {
            return SecuritySection(
              enabled: state.enabled,
              capability: state.capability,
              availableBiometrics: state.availableBiometrics,
              busy: state.toggleStatus == RequestStatus.loading,
              onToggle: (enable) => context.read<SecurityBloc>().add(
                SecurityAppLockToggled(enable: enable),
              ),
            );
          },
        );
      },
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
                colorFilter: ColorFilter.mode(colors.error, BlendMode.srcIn),
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
