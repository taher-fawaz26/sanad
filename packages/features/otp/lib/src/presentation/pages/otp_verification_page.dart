import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp/src/domain/entities/otp_result.dart';
import 'package:otp/src/presentation/bloc/otp/otp_bloc.dart';
import 'package:otp/src/presentation/config/otp_flow_config.dart';
import 'package:otp/src/presentation/view/otp_success_view.dart';
import 'package:otp/src/presentation/view/otp_verification_view.dart';

/// Hosts `OtpBloc` and swaps between `OtpVerificationView` and
/// `OtpSuccessView`. Presentation-neutral — `OtpFlow` decides whether this is
/// pushed as a sheet or a plain page.
///
/// Pops itself with an [OtpResult] once verified. Any other dismissal (back
/// button, barrier tap, drag-to-dismiss) pops with `null`, which `OtpFlow`
/// maps to `OtpCancelled`.
class OtpVerificationPage<T> extends StatelessWidget {
  const OtpVerificationPage({required this.config, super.key});

  final OtpFlowConfig<T> config;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OtpBloc<T>(config: config)..add(const OtpStarted()),
      child: BlocConsumer<OtpBloc<T>, OtpState<T>>(
        listenWhen: (previous, current) =>
            previous.phase.runtimeType != current.phase.runtimeType,
        listener: (context, state) async {
          if (state.phase is! OtpVerifiedPhase) return;
          if (config.showSuccessScreen) {
            await Future<void>.delayed(config.successAutoCloseDelay);
          }
          if (context.mounted) {
            Navigator.of(
              context,
            ).pop<OtpResult<T>>(OtpVerified<T>(state.verifiedData as T));
          }
        },
        builder: (context, state) {
          if (state.phase is OtpVerifiedPhase && config.showSuccessScreen) {
            return OtpSuccessView(channel: config.channel);
          }
          return OtpVerificationView<T>(config: config);
        },
      ),
    );
  }
}
