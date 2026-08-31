import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_cubit.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_routes.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_state.dart';

/// "What should I call you?" (Figma `7002:27991`) — the first post-
/// authentication setup screen, reached after OTP when the verified account
/// has no display name yet (`user.name == null`).
///
/// Submitting a valid name saves it via `PATCH clients/me`
/// ([AccountSetupCubit.submitName]); the screen advances to Get Notified only
/// after the save succeeds, and preserves the entered value on failure.
class EnterNamePage extends HookWidget {
  /// Creates an [EnterNamePage].
  const EnterNamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final controller = useTextEditingController();
    final isValid = useState(false);

    useEffect(() {
      void listener() => isValid.value = PersonNameValidator.isValid(
        controller.text.trim(),
        minWords: 1,
      );
      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    void onNext() {
      context.read<AccountSetupCubit>().submitName(controller.text.trim());
    }

    return BlocListener<AccountSetupCubit, AccountSetupState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case RequestStatus.success:
            context.push(AccountSetupRoutes.getNotified);
          case RequestStatus.failure:
            if (state.failure != null) {
              showAppErrorSnackbar(
                context: context,
                title: state.failure!.localizedMessage(),
              );
            }
          case RequestStatus.initial:
          case RequestStatus.loading:
            break;
        }
      },
      child: Scaffold(
        appBar: AppNavBar(
          title: '',
          showBackButton: true,
          onLeadingTap: () => context.pop(),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsiveDimension(AppSpacing.xxl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scrolls instead of overflowing on short screens — the Next
                // button below stays pinned regardless of content height.
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: responsiveDimension(AppSpacing.xxxxl)),
                        Container(
                          width: responsiveDimension(56),
                          height: responsiveDimension(56),
                          decoration: BoxDecoration(
                            color: colors.palettes.sky.shade100,
                            borderRadius: AppRadius.circularXl,
                          ),
                          child: Center(
                            child: AppSvgPicture.asset(
                              AppSvgs.registrationProfile,
                              width: responsiveDimension(AppDimension.iconMenu),
                              height: responsiveDimension(
                                AppDimension.iconMenu,
                              ),
                              // registration_profile.svg ships hardcoded at
                              // #131927 (its original "Individual Details
                              // header" context) — this frame's icon is
                              // sky/700 (#48555C), matching every other
                              // onboarding icon circle (Email, Phone, OTP).
                              // Same shape, different tint: not a duplicate
                              // asset, just recolored for this usage.
                              colorFilter: ColorFilter.mode(
                                colors.palettes.sky.shade700,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: responsiveDimension(AppSpacing.xxl)),
                        Text(
                          'enter_name.title'.tr(),
                          style: typography.title3.copyWith(
                            fontSize: 28.rfs,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsiveDimension(AppSpacing.sm)),
                        Text(
                          'enter_name.subtitle'.tr(),
                          style: typography.regularNormal.copyWith(
                            fontSize: 15.rfs,
                            height: 1.4,
                            color: colors.textMuted,
                          ),
                        ),
                        SizedBox(height: responsiveDimension(AppSpacing.xxl)),
                        AppTextField(
                          controller: controller,
                          label: 'enter_name.field_label'.tr(),
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.done,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onSubmitted: (_) {
                            if (isValid.value) onNext();
                          },
                          validator: (value) {
                            if (!RequiredValidator.isValid(value)) {
                              return 'validation.required'.tr();
                            }
                            if (!PersonNameValidator.isValid(
                              value!.trim(),
                              minWords: 1,
                            )) {
                              return 'validation.invalid_name'.tr();
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                AppPageEntrance(
                  distance: 10,
                  child: BlocBuilder<AccountSetupCubit, AccountSetupState>(
                    builder: (context, state) {
                      final isLoading = state.status == RequestStatus.loading;
                      return AppButton(
                        label: 'common.next'.tr(),
                        isLoading: isLoading,
                        onPressed: isValid.value && !isLoading ? onNext : null,
                      );
                    },
                  ),
                ),
                SizedBox(height: responsiveDimension(AppSpacing.lg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
