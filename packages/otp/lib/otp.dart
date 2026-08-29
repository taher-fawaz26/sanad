/// Reusable OTP verification flow.
///
/// Any feature invokes verification with `OtpFlow.start(context, config)` —
/// the caller supplies an `OtpVerifier` and gets back an `OtpResult`. This
/// package owns no network endpoints and no feature-specific UI.
library;

export 'src/data/verifiers/callback_otp_verifier.dart';
export 'src/di/otp_di.dart';
export 'src/domain/contracts/otp_verifier.dart';
export 'src/domain/entities/otp_cooldown.dart';
export 'src/domain/entities/otp_delivery.dart';
export 'src/domain/entities/otp_result.dart';
export 'src/domain/enums/otp_channel.dart';
export 'src/domain/enums/otp_purpose.dart';
export 'src/module/otp_module.dart';
export 'src/presentation/config/otp_flow_config.dart';
export 'src/presentation/flow/otp_flow.dart';
export 'src/presentation/view/otp_host.dart';
export 'src/presentation/view/otp_view.dart';
