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

/// Continue with Email (Figma `6979:27423`).
///
/// The email address is validated locally (reusing the same
/// [RequiredValidator]/[EmailValidator] pair and
/// `validation.required`/`auth.invalid_email` copy as `packages/auth`'s
/// `AuthPage`). "Next" dispatches the unified client OTP
/// (`POST auth/client/request-otp`) via [ClientOtpRequestCubit] and navigates
/// to the shared OTP screen (`OAuthRoutes.otp`) **only** once a code is live —
/// the exact trimmed address is carried through unchanged and reused verbatim
/// by verify. There is no register/login branching: the server decides.
class OAuthEmailPage extends StatelessWidget {
  /// Creates an [OAuthEmailPage].
  const OAuthEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClientOtpRequestCubit(sl<RequestClientOtpUseCase>()),
      child: const _OAuthEmailView(),
    );
  }
}

class _OAuthEmailView extends HookWidget {
  const _OAuthEmailView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final controller = useTextEditingController();
    final isValid = useState(false);

    useEffect(() {
      void listener() =>
          isValid.value = EmailValidator.isValid(controller.text.trim());
      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    void onNext() {
      // The identifier is normalized (trimmed) exactly once, here, and reused
      // verbatim for verify via the OTP route args — never re-normalized.
      context.read<ClientOtpRequestCubit>().request(
        method: ClientAuthMethod.email,
        value: controller.text.trim(),
      );
    }

    return BlocListener<ClientOtpRequestCubit, ClientOtpRequestState>(
      listener: (context, state) {
        switch (state) {
          case ClientOtpRequestReady():
            context.push(
              OAuthRoutes.otp,
              extra: OAuthOtpRouteArgs(
                channel: OtpChannel.email,
                destination: controller.text.trim(),
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
                    child: AppStaggeredColumn(
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
                              AppSvgs.sendMail,
                              width: responsiveDimension(AppDimension.iconMenu),
                              height: responsiveDimension(
                                AppDimension.iconMenu,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: responsiveDimension(AppSpacing.xxl)),
                        Text(
                          'oauth.email_title'.tr(),
                          style: typography.title3.copyWith(
                            fontSize: 28.rfs,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsiveDimension(AppSpacing.sm)),
                        Text(
                          'oauth.email_subtitle'.tr(),
                          style: typography.regularNormal.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                        SizedBox(height: responsiveDimension(AppSpacing.xxl)),
                        AppTextField(
                          controller: controller,
                          label: 'oauth.email_label'.tr(),
                          hint: 'oauth.email_hint'.tr(),
                          isLtr: true,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onSubmitted: (_) {
                            if (isValid.value) onNext();
                          },
                          validator: (value) {
                            if (!RequiredValidator.isValid(value)) {
                              return 'validation.required'.tr();
                            }
                            if (!EmailValidator.isValid(value!.trim())) {
                              return 'auth.invalid_email'.tr();
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
