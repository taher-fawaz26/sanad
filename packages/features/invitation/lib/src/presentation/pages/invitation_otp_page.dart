import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:invitation/src/domain/entities/invitation_mock.dart';
import 'package:invitation/src/routes/invitation_routes.dart';
import 'package:otp/otp.dart';

/// Screen 2 — OTP entry (Figma `2560:24688`).
///
/// UI-only: verification doesn't call any API — [CallbackOtpVerifier] mocks
/// a short delay then always succeeds. All OTP UI/state lives in the `otp`
/// package; this page only bridges the mocked verifier to it and routes on
/// the result.
class InvitationOtpPage extends StatefulWidget {
  const InvitationOtpPage({
    this.invitation = InvitationMock.sample,
    super.key,
  });

  final InvitationMock invitation;

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
    final result = await OtpFlow.start<void>(
      context,
      OtpFlowConfig<void>(
        channel: OtpChannel.email,
        destination: widget.invitation.email,
        presentAsSheet: false,
        verifier: CallbackOtpVerifier<void>(
          onRequestCode: () => TaskEither.right(const OtpDelivery()),
          onVerifyCode: (_) => TaskEither<Failure, void>(() async {
            await Future<void>.delayed(const Duration(milliseconds: 600));
            return right(null);
          }),
        ),
      ),
    );

    if (!mounted) return;

    if (result.isVerified) {
      context.pushReplacement(
        InvitationRoutes.success,
        extra: widget.invitation,
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
