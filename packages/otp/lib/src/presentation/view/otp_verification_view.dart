import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp/src/presentation/bloc/otp/otp_bloc.dart';
import 'package:otp/src/presentation/config/otp_flow_config.dart';

/// Body of the OTP flow while awaiting/verifying a code: title, destination
/// + Change, pin field, inline error, resend timer.
class OtpVerificationView<T> extends StatefulWidget {
  const OtpVerificationView({required this.config, super.key});

  final OtpFlowConfig<T> config;

  @override
  State<OtpVerificationView<T>> createState() => _OtpVerificationViewState<T>();
}

class _OtpVerificationViewState<T> extends State<OtpVerificationView<T>> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatSeconds(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final config = widget.config;

    return BlocBuilder<OtpBloc<T>, OtpState<T>>(
      builder: (context, state) {
        final bloc = context.read<OtpBloc<T>>();
        final errorText = switch (state.phase) {
          OtpInvalidCode() => 'otp.invalid_code'.tr(),
          OtpExpiredPhase() => 'otp.expired_code'.tr(),
          OtpFailurePhase(:final failure) => failure.messageKey.tr(),
          _ => null,
        };
        final isVerifying = state.phase is OtpVerifying;
        final isSending = state.phase is OtpSending;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                config.titleBuilder?.call(context, config) ?? 'otp.title'.tr(),
                style: typography.title3.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: AppSpacing.sm),
              RichText(
                text: TextSpan(
                  style: typography.regularNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text:
                          config.subtitleBuilder?.call(context, config) ??
                          'otp.subtitle'.tr(
                            namedArgs: {'destination': state.destination},
                          ),
                    ),
                    if (config.onChangeDestination != null)
                      TextSpan(
                        text: ' ${'common.change'.tr()}',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: (TapGestureRecognizer()
                          ..onTap = () async {
                            final next = await config.onChangeDestination!(
                              context,
                            );
                            if (next != null && context.mounted) {
                              bloc.add(OtpDestinationChanged(next));
                            }
                          }),
                      ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              AppOtpField(
                controller: _controller,
                length: config.length,
                enabled: !isVerifying && !isSending,
                errorText: errorText,
                onChanged: (value) => bloc.add(OtpCodeChanged(value)),
                onCompleted: config.autoSubmit
                    ? (value) => bloc.add(OtpSubmitted(value))
                    : null,
              ),
              SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'otp.verify'.tr(),
                onPressed: isVerifying || isSending || state.code.isEmpty
                    ? null
                    : () => bloc.add(const OtpSubmitted()),
                isLoading: isVerifying,
              ),
              SizedBox(height: AppSpacing.lg),
              if (state.phase is! OtpIdle && !isSending)
                if (state.canResend)
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          '${'otp.not_received'.tr()} ',
                          style: typography.regularNormal.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => bloc.add(const OtpResendRequested()),
                          child: Text(
                            'otp.send_again'.tr(),
                            style: typography.regularNormal.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Center(
                    child: Text(
                      _formatSeconds(state.secondsRemaining),
                      style: typography.regularNormal.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
