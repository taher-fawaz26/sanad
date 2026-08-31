import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:otp/otp.dart';
import 'package:sanad_client/src/features/oauth/client_otp_request_cubit.dart';
import 'package:sanad_client/src/features/oauth/oauth_otp_route_args.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';

/// Continue with Phone (Figma `7045:13678`).
///
/// The phone number is validated locally with the shared [UaePhoneValidator]
/// and normalized to E.164 via [UaePhoneValidator.normalize] — the same
/// convention `contact_change_sheet.dart` uses. "Next" dispatches the unified
/// client OTP (`POST auth/client/request-otp`) via [ClientOtpRequestCubit] and
/// navigates to the shared OTP screen only once a code is live; the normalized
/// number is carried through unchanged and reused verbatim by verify.
class OAuthPhonePage extends StatelessWidget {
  /// Creates an [OAuthPhonePage].
  const OAuthPhonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClientOtpRequestCubit(sl<RequestClientOtpUseCase>()),
      child: const _OAuthPhoneView(),
    );
  }
}

class _OAuthPhoneView extends HookWidget {
  const _OAuthPhoneView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final controller = useTextEditingController();
    final isValid = useState(false);

    useEffect(() {
      void listener() =>
          isValid.value = UaePhoneValidator.isMobile(controller.text);
      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    void onNext() {
      context.read<ClientOtpRequestCubit>().request(
        method: ClientAuthMethod.phone,
        value: UaePhoneValidator.normalize(controller.text),
      );
    }

    return BlocListener<ClientOtpRequestCubit, ClientOtpRequestState>(
      listener: (context, state) {
        switch (state) {
          case ClientOtpRequestReady():
            context.push(
              OAuthRoutes.otp,
              extra: OAuthOtpRouteArgs(
                channel: OtpChannel.phone,
                destination: UaePhoneValidator.normalize(controller.text),
              ),
            );
          case ClientOtpRequestFailure(:final failure):
            showAppErrorSnackbar(
              context: context,
              title: failure.localizedMessage(),
            );
          case ClientOtpRequestInitial():
          case ClientOtpRequestInProgress():
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
                              AppSvgs.smartphoneDevice,
                              width: responsiveDimension(AppDimension.iconMenu),
                              height: responsiveDimension(
                                AppDimension.iconMenu,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: responsiveDimension(AppSpacing.xxl)),
                        Text(
                          'oauth.phone_title'.tr(),
                          style: typography.title3.copyWith(
                            fontSize: 28.rfs,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsiveDimension(AppSpacing.sm)),
                        Text(
                          'oauth.phone_subtitle'.tr(),
                          style: typography.regularNormal.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                        SizedBox(height: responsiveDimension(AppSpacing.xxl)),
                        AppPhoneField(
                          label: 'oauth.phone_number_label'.tr(),
                          hint: 'oauth.phone_hint'.tr(),
                          controller: controller,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) =>
                              UaePhoneValidator.mobileValidationMessage(
                                value,
                              )?.tr(),
                        ),
                      ],
                    ),
                  ),
                ),
                AppPageEntrance(
                  distance: 10,
                  child:
                      BlocBuilder<ClientOtpRequestCubit, ClientOtpRequestState>(
                        builder: (context, state) {
                          final isLoading = state is ClientOtpRequestInProgress;
                          return AppButton(
                            label: 'oauth.next'.tr(),
                            isLoading: isLoading,
                            onPressed: isValid.value && !isLoading
                                ? onNext
                                : null,
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
