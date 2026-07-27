import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:otp/otp.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
import 'package:registration/src/presentation/widgets/registration_header.dart';
import 'package:registration/src/routes/registration_routes.dart';

const _kResendCooldown = 90;

class SignUpOtpPage extends HookWidget {
  const SignUpOtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final secondsLeft = useState(_kResendCooldown);
    final canResend = useState(false);

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (secondsLeft.value <= 1) {
          t.cancel();
          secondsLeft.value = 0;
          canResend.value = true;
        } else {
          secondsLeft.value--;
        }
      });
      return timer.cancel;
    }, const []);

    final email = context.watch<RegistrationCubit>().state.email;
    final colors = context.appColors;
    final typography = context.appTypography;

    final minutes = (secondsLeft.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft.value % 60).toString().padLeft(2, '0');

    void resend() {
      if (!canResend.value) return;
      secondsLeft.value = _kResendCooldown;
      canResend.value = false;
      controller.clear();
      // TODO(registration): trigger resend OTP API call
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistrationHeader(
          title: 'Enter OTP',
          subtitle: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Please enter the OTP sent to\n'),
                TextSpan(
                  text: email,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: 'change',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => context.pop(),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
        Center(
          child: AppOtpField(
            controller: controller,
            autofocus: true,
            onCompleted: (_) {},
          ),
        ),
        SizedBox(height: responsiveDimension(AppSpacing.xl)),
        AppButton(
          label: 'Submit',
          onPressed: () {
            if (controller.text.length < 5) return;
            context.push(RegistrationRoutes.selectAccountType);
          },
        ),
        SizedBox(height: responsiveDimension(AppSpacing.xl)),
        if (!canResend.value)
          Center(
            child: Text(
              '$minutes:$seconds',
              style: typography.regularNormal.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        SizedBox(height: responsiveDimension(AppSpacing.xl)),
        Center(
          child: Text.rich(
            TextSpan(
              style: typography.regularNormal.copyWith(
                color: colors.textSecondary,
              ),
              children: [
                const TextSpan(text: "Don't receive OTP ? "),
                TextSpan(
                  text: 'Send again',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: canResend.value
                      ? (TapGestureRecognizer()..onTap = resend)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
