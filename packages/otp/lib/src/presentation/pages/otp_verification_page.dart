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
        Navigator.of(context).pop<OtpResult<T>>(result);
      },
    );
  }
}
