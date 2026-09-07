import 'package:flutter/material.dart';
import 'package:otp/src/presentation/config/otp_flow_config.dart';
import 'package:otp/src/presentation/config/otp_visual_style.dart';
import 'package:otp/src/presentation/view/layouts/client_otp_layout.dart';
import 'package:otp/src/presentation/view/layouts/provider_otp_layout.dart';

/// The OTP screen.
///
/// There is one OTP implementation — one bloc, one verifier contract, one set
/// of parts (`otp_parts.dart`) — and two **visual specifications** on top of
/// it, because the client and provider products are drawn to different
/// designs. This widget owns the code controller and picks the layout; it is
/// deliberately the only place that knows both styles exist.
///
/// The style resolves in this order:
///
/// 1. `OtpFlowConfig.style`, when a single flow pins itself to one spec;
/// 2. the app-level [OtpStyleScope] each app installs above its router —
///    this is what lets the OTP call sites inside shared packages (`auth`,
///    `account_settings`, `contact_verification`) render the right product's
///    design without knowing which app they were compiled into;
/// 3. [OtpVisualStyle.provider], the spec the shared `otp.*` copy was
///    written against.
///
/// Presentation (page vs bottom sheet) is orthogonal and comes from
/// `OtpFlowConfig.presentation`; both layouts honour it.
class OtpView<T> extends StatefulWidget {
  const OtpView({required this.config, super.key});

  final OtpFlowConfig<T> config;

  @override
  State<OtpView<T>> createState() => _OtpViewState<T>();
}

class _OtpViewState<T> extends State<OtpView<T>> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final style =
        config.style ??
        OtpStyleScope.maybeOf(context) ??
        OtpVisualStyle.provider;

    return switch (style) {
      OtpVisualStyle.client => ClientOtpLayout<T>(
        config: config,
        controller: _controller,
      ),
      OtpVisualStyle.provider => ProviderOtpLayout<T>(
        config: config,
        controller: _controller,
      ),
    };
  }
}
