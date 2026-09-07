import 'package:flutter/widgets.dart';
import 'package:otp/src/domain/entities/otp_result.dart';
import 'package:otp/src/presentation/config/otp_flow_config.dart';
import 'package:otp/src/presentation/view/otp_host.dart';

/// Route-hosted OTP flow: an [OtpHost] that pops itself with the result.
///
/// Presentation-neutral — `OtpFlow` decides whether this is pushed as a sheet
/// or a plain page. Any dismissal that is not a terminal outcome (back
/// button, barrier tap, drag) pops with `null`, which `OtpFlow` maps to
/// `OtpCancelled`.
class OtpVerificationPage<T> extends StatelessWidget {
  const OtpVerificationPage({required this.config, super.key});

  final OtpFlowConfig<T> config;

  @override
  Widget build(BuildContext context) {
    return OtpHost<T>(
      config: config,
      onResult: (result) {
        if (!context.mounted) return;
        // Pop *this* route or nothing. A result can still arrive after the
        // user dismissed the flow — the success screen auto-closes on a timer
        // — and popping then removes whichever route is now on top instead.
        // In the contact-change flow that is the caller's own sheet, whose
        // result type is a `String`, so the stray pop crashed on
        // `OtpVerified<T> is not a subtype of String?` rather than merely
        // navigating somewhere unexpected.
        final route = ModalRoute.of(context);
        if (route == null || !route.isCurrent) return;
        Navigator.of(context).pop<OtpResult<T>>(result);
      },
    );
  }
}
