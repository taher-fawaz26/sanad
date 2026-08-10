import 'package:flutter/material.dart';
import 'package:otp/src/domain/entities/otp_result.dart';
import 'package:otp/src/presentation/config/otp_flow_config.dart';
import 'package:otp/src/presentation/pages/otp_verification_page.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Public entry point — the only thing a caller needs to know about this
/// package.
///
/// ```dart
/// final result = await OtpFlow.start<VerificationResult>(
///   context,
///   OtpFlowConfig.email(destination: email, verifier: myVerifier),
/// );
/// if (result case OtpVerified(:final data)) { ... }
/// ```
abstract final class OtpFlow {
  OtpFlow._();

  static Future<OtpResult<T>> start<T>(
    BuildContext context,
    OtpFlowConfig<T> config,
  ) async {
    final page = OtpVerificationPage<T>(config: config);

    OtpResult<T>? result;
    if (config.presentAsSheet) {
      result = await SheetNavigator.push<OtpResult<T>>(
        context,
        page,
        // OTP is a long-form flow (title + field + timer + resend) — not a
        // short action sheet, so it always takes the full sheet height.
        settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
      );
    } else {
      // Page mode has no host chrome of its own — give it a bare AppBar so
      // Android back / iOS swipe-back have something to pop.
      result = await Navigator.of(context, rootNavigator: true)
          .push<OtpResult<T>>(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(),
                body: SafeArea(child: page),
              ),
            ),
          );
    }

    return result ?? OtpCancelled<T>();
  }
}
