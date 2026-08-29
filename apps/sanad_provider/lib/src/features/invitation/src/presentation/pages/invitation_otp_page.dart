import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:otp/otp.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/accept_invitation_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/get_invitation_resend_info_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/request_invitation_otp_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/resend_invitation_otp_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/verifiers/invitation_otp_verifier.dart';
import 'package:sanad_provider/src/features/invitation/src/routes/invitation_routes.dart';
import 'package:sanad_provider/src/features/invitation/src/routing/invitation_route_args.dart';

/// Screen 2 — OTP entry (Figma `2560:24688`).
///
/// The shared OTP engine owns the whole sequence: it probes
/// `resend-info/{token}`, sends via `request-otp` only when no session is
/// live, and routes resend taps to `resend-otp`. Verifying calls
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
    final result = await OtpFlow.start<AuthSessionEntity>(
      context,
      OtpFlowConfig<AuthSessionEntity>(
        channel: OtpChannel.email,
        destination: widget.args.preview.email ?? '',
        presentation: OtpPresentation.page,
        verifier: InvitationOtpVerifier(
          token: widget.args.token,
          requestOtp: sl<RequestInvitationOtpUseCase>(),
          resendOtp: sl<ResendInvitationOtpUseCase>(),
          getResendInfo: sl<GetInvitationResendInfoUseCase>(),
          acceptInvitation: sl<AcceptInvitationUseCase>(),
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
