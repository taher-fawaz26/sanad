import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart' show showAppErrorSnackbar;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/accept_invitation_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/get_invitation_resend_info_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/request_invitation_otp_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/resend_invitation_otp_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/usecase_params.dart';
import 'package:sanad_provider/src/features/invitation/src/routes/invitation_routes.dart';
import 'package:sanad_provider/src/features/invitation/src/routing/invitation_route_args.dart';
import 'package:localization/localization.dart';
import 'package:otp/otp.dart';

/// Screen 2 — OTP entry (Figma `2560:24688`).
///
/// Sequencing: `request-otp` fires once here (details already verified the
/// token, but never sent a code), then `GET resend-info` seeds the
/// server-driven cooldown before the shared `otp` package's sheet opens
/// with `autoSendOnStart: false` — the code is already in flight by then.
/// Every subsequent resend tap calls `resend-otp` (a different endpoint from
/// the initial send, per the live contract). Verifying calls
/// `POST /workers/invitations/accept`, and a success persists the returned
/// session via [SessionManager.save] before routing to the success screen.
class InvitationOtpPage extends StatefulWidget {
  const InvitationOtpPage({required this.args, super.key});

  final InvitationOtpRouteArgs args;

  @override
  State<InvitationOtpPage> createState() => _InvitationOtpPageState();
}

class _InvitationOtpPageState extends State<InvitationOtpPage> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startFlow());
  }

  Future<void> _startFlow() async {
    final token = widget.args.token;
    final params = InvitationTokenParams(token: token);

    final bootstrap = await sl<RequestInvitationOtpUseCase>()(
      params,
    ).flatMap((_) => sl<GetInvitationResendInfoUseCase>()(params)).run();

    if (!mounted) return;

    final resendInfo = bootstrap.fold((failure) {
      showAppErrorSnackbar(context: context, title: failure.localizedMessage());
      context.pop();
      return null;
    }, (info) => info);

    if (resendInfo == null) return;

    final result = await OtpFlow.start<AuthSessionEntity>(
      context,
      OtpFlowConfig<AuthSessionEntity>(
        channel: OtpChannel.email,
        destination: widget.args.preview.email ?? '',
        presentAsSheet: false,
        autoSendOnStart: false,
        resendCooldown: Duration(seconds: resendInfo.remainingSeconds),
        verifier: CallbackOtpVerifier<AuthSessionEntity>(
          onRequestCode: () => sl<ResendInvitationOtpUseCase>()(
            params,
          ).map((_) => const OtpDelivery()),
          onVerifyCode: (code) => sl<AcceptInvitationUseCase>()(
            AcceptInvitationParams(token: token, otp: code),
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (result case OtpVerified<AuthSessionEntity>(:final data)) {
      await sl<SessionManager>().save(data);
      if (!mounted) return;
      context.pushReplacement(
        InvitationRoutes.success,
        extra: InvitationSuccessRouteArgs(
          preview: widget.args.preview,
          session: data,
        ),
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
