import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp/src/domain/entities/otp_result.dart';
import 'package:otp/src/presentation/bloc/otp/otp_bloc.dart';
import 'package:otp/src/presentation/config/otp_flow_config.dart';
import 'package:otp/src/presentation/view/otp_success_view.dart';
import 'package:otp/src/presentation/view/otp_view.dart';

/// Owns an [OtpBloc] and renders the canonical [OtpView], reporting the
/// outcome through [onResult].
///
/// Exists so the two ways of showing OTP — a pushed route that pops with a
/// result, and a screen embedded in a host's own chrome (the auth shell) —
/// share one implementation. A caller that embeds this gets exactly the same
/// UI and state machine as one that pushes it; only the delivery of the
/// result differs.
class OtpHost<T> extends StatelessWidget {
  const OtpHost({required this.config, required this.onResult, super.key});

  final OtpFlowConfig<T> config;

  /// Called once, when the flow reaches a terminal outcome.
  final void Function(OtpResult<T> result) onResult;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OtpBloc<T>(config: config)..add(const OtpStarted()),
      child: BlocConsumer<OtpBloc<T>, OtpState<T>>(
        listenWhen: (previous, current) =>
            previous.phase.runtimeType != current.phase.runtimeType,
        listener: (context, state) async {
          // A conflict is terminal — the target was claimed while the code was
          // outstanding, so there is nothing the user can retype. Hand the
          // failure back rather than collapsing it to a plain cancellation.
          if (state.phase case OtpConflict(:final failure)) {
            onResult(OtpFailed<T>(failure));
            return;
          }
          if (state.phase is! OtpVerifiedPhase) return;
          final data = state.verifiedData;
          if (data == null) return;
          if (config.showSuccessScreen) {
            await Future<void>.delayed(config.successAutoCloseDelay);
            // The success screen is dismissible: a back press, drag or barrier
            // tap during those seconds tears this subtree down while the timer
            // is still pending. Reporting a result then pops a route that is
            // no longer ours.
            if (!context.mounted) return;
          }
          onResult(OtpVerified<T>(data));
        },
        builder: (context, state) {
          if (state.phase is OtpVerifiedPhase && config.showSuccessScreen) {
            return OtpSuccessView(channel: config.channel);
          }
          return OtpView<T>(config: config);
        },
      ),
    );
  }
}
