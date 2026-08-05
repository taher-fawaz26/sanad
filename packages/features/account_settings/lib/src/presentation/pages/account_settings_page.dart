import 'package:account_settings/src/presentation/widgets/bottom_sheets/language_preferences_bottom_sheet.dart';
import 'package:account_settings/src/presentation/widgets/sections/account_credentials_section.dart';
import 'package:account_settings/src/presentation/widgets/sections/help_support_section.dart';
import 'package:account_settings/src/presentation/widgets/sections/language_preferences_section.dart';
import 'package:app_assets/app_assets.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';

/// Account settings hub — Figma `3821:18875`.
///
/// Shared by provider and client. Composes credential, language, help, and
/// delete-account flows from existing design-system widgets.
class AccountSettingsPage extends StatefulWidget {
  /// Creates the account settings page.
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  UserEntity? _userFromState(AuthState state) => switch (state) {
    AuthAuthenticatedState(:final user) => user,
    AuthCheckSignInStatusSuccessState(:final user) => user,
    AuthDeleteAccountLoadingState(:final user) => user,
    AuthDeleteAccountFailureState(:final user) => user,
    _ => null,
  };

  String _languageLabel(String code) =>
      code == 'en' ? 'app.english'.tr() : 'app.arabic'.tr();

  Future<void> _openLanguageSheet() async {
    final translateBloc = context.read<TranslateBloc>();
    final currentCode = translateBloc.state.languageCode;

    final result = await showLanguagePreferencesBottomSheet(
      context: context,
      initialLanguageCode: currentCode,
    );
    if (result == null || !mounted) return;

    final locale = result == 'en'
        ? const Locale('en', 'US')
        : const Locale('ar', 'AR');

    await context.setLocale(locale);
    if (!mounted) return;

    translateBloc.add(
      result == 'ar' ? TrArabicEvent() : TrEnglishEvent(),
    );
  }

  Future<void> _confirmDeleteAccount(UserEntity user) async {
    final confirmed = await showAppPopover<bool>(
      context: context,
      title: 'settings.delete_account'.tr(),
      description: 'settings.delete_account_confirm_description'.tr(),
      imageLayout: AppDialogImageLayout.iconSmall,
      featureIconColor: AppFeatureIconColor.error,
      featureIconSize: AppFeatureIconSize.lg,
      featureIconTheme: AppFeatureIconTheme.lightCircleOutline,
      actions: AppPopoverActions.dual,
      primaryLabel: 'settings.delete_account_confirm'.tr(),
      primaryDestructive: true,
      secondaryLabel: 'settings.cancel'.tr(),
      onPrimary: () => Navigator.of(context, rootNavigator: true).pop(true),
      onSecondary: () => Navigator.of(context, rootNavigator: true).pop(false),
    );

    if (confirmed ?? false) {
      context.read<AuthBloc>().add(AuthDeleteAccountEvent(user.id));
    }
  }

  void _showComingSoon() {
    showAppSnackbar(
      context: context,
      title: 'settings.coming_soon'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sectionSpacing = AppSpacing.lg;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthLogoutSuccessState ||
          current is AuthDeleteAccountFailureState,
      listener: (context, state) {
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
        final user = _userFromState(authState);
        final isDeleting = authState is AuthDeleteAccountLoadingState;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: colors.surface,
              appBar: AppNavBar(
                title: 'settings.account_settings'.tr(),
                showBackButton: true,
                onLeadingTap: () => context.pop(),
              ),
              body: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        AccountCredentialsSection(
                          email: user?.email,
                          emailVerified: user?.isVerified ?? false,
                          onAddPhone: _showComingSoon,
                          onChangePhone: _showComingSoon,
                          onAddEmail: _showComingSoon,
                          onChangeEmail: _showComingSoon,
                        ),
                        SizedBox(height: sectionSpacing),
                        BlocBuilder<TranslateBloc, TranslateState>(
                          builder: (context, translateState) {
                            return LanguagePreferencesSection(
                              selectedLanguageLabel: _languageLabel(
                                translateState.languageCode,
                              ),
                              onTap: _openLanguageSheet,
                            );
                          },
                        ),
                        SizedBox(height: sectionSpacing),
                        HelpSupportSection(
                          onContactSupport: _showComingSoon,
                          onTermsOfService: _showComingSoon,
                          onPrivacyPolicy: _showComingSoon,
                        ),
                        SizedBox(height: sectionSpacing),
                        _DeleteAccountRow(
                          onTap: user == null
                              ? null
                              : () => _confirmDeleteAccount(user),
                        ),
                        SizedBox(height: AppSpacing.xl),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            if (isDeleting)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: Center(child: AppLoadingIndicator()),
                ),
              ),
          ],
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
              ),
              SizedBox(width: AppSpacing.lg),
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
