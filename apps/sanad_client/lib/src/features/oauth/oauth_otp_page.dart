import 'dart:async';

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:otp/otp.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_routes.dart';
import 'package:sanad_client/src/features/oauth/oauth_otp_route_args.dart';
import 'package:sanad_client/src/routing/client_routes.dart';

/// Builds the [OtpFlowConfig] for the OAuth Email/Phone verification step.
///
/// Centralizes the copy/behavior that differs from the shared package
/// defaults (see [OtpFlowConfig.verifyLabel]/[OtpFlowConfig.pinActionToBottom]
/// doc comments for why): "Next" instead of "Verify", the button pinned to the
/// bottom of the screen, a channel-specific subtitle, and no success screen
/// (this flow owns its own post-verify routing, so a confirmation screen would
/// only sit between the user and the app). `autoSubmit` is off — the pinned
/// "Next" button is the sole submit trigger, so re-editing a full code never
/// re-fires verification and burns an attempt (cf. SAN-539). The code was
/// already dispatched on the Email/Phone screen, so `autoSendOnStart` is false
/// while the cooldown probe still reads `resend-info` for the countdown.
OtpFlowConfig<ClientVerifyResult> buildOAuthOtpConfig({
  required OtpChannel channel,
  required String destination,
  required OtpVerifier<ClientVerifyResult> verifier,
  bool autoSendOnStart = false,
}) {
  String subtitleBuilder(
    BuildContext context,
    OtpFlowConfig<ClientVerifyResult> config,
  ) => channel == OtpChannel.email
      ? 'oauth.otp_subtitle_email'.tr()
      : 'oauth.otp_subtitle_phone'.tr();

  return switch (channel) {
    OtpChannel.email => OtpFlowConfig<ClientVerifyResult>.email(
      destination: destination,
      verifier: verifier,
      presentation: OtpPresentation.page,
      subtitleBuilder: subtitleBuilder,
      verifyLabel: 'oauth.next'.tr(),
      pinActionToBottom: true,
      autoSendOnStart: autoSendOnStart,
      autoSubmit: false,
      showSuccessScreen: false,
    ),
    OtpChannel.phone => OtpFlowConfig<ClientVerifyResult>.phone(
      destination: destination,
      verifier: verifier,
      presentation: OtpPresentation.page,
      subtitleBuilder: subtitleBuilder,
      verifyLabel: 'oauth.next'.tr(),
      pinActionToBottom: true,
      autoSendOnStart: autoSendOnStart,
      autoSubmit: false,
      showSuccessScreen: false,
    ),
  };
}

/// Builds the [OAuthOtpPage] route destination for `OAuthRoutes.otp` from its
/// [OAuthOtpRouteArgs] `extra` — see `client_router.dart`.
///
/// Wires the real, backend-backed [ClientAuthOtpVerifier] (unified client
/// sign-in — request/verify/resend keyed on the exact `{method, value}` the
/// code was requested for). There is no placeholder and no "any 6 digits"
/// acceptance any more: every code is verified against
/// `POST auth/client/verify`.
Widget buildOAuthOtpRoutePage(BuildContext context, OAuthOtpRouteArgs args) {
  final verifier = ClientAuthOtpVerifier(
    method: ClientAuthMethod.fromChannel(args.channel),
    value: args.destination,
    requestOtp: sl<RequestClientOtpUseCase>(),
    verifyOtp: sl<VerifyClientOtpUseCase>(),
    getResendInfo: sl<GetClientResendInfoUseCase>(),
  );
  return OAuthOtpPage(
    config: buildOAuthOtpConfig(
      channel: args.channel,
      destination: args.destination,
      verifier: verifier,
    ),
  );
}

/// Hosts the canonical [OtpView] (via [OtpHost]) behind the same
/// `Scaffold`/`AppNavBar` shell the other OAuth screens use, and routes the
/// verify outcome per the server-driven client contract.
class OAuthOtpPage extends StatefulWidget {
  /// Creates an [OAuthOtpPage].
  const OAuthOtpPage({required this.config, super.key});

  /// Built by [buildOAuthOtpConfig].
  final OtpFlowConfig<ClientVerifyResult> config;

  @override
  State<OAuthOtpPage> createState() => _OAuthOtpPageState();
}

class _OAuthOtpPageState extends State<OAuthOtpPage> {
  void _handleResult(OtpResult<ClientVerifyResult> result) {
    switch (result) {
      case OtpVerified<ClientVerifyResult>(:final data):
        unawaited(_handleVerified(data));
      case OtpFailed<ClientVerifyResult>(:final failure):
        // A terminal verify failure (e.g. the identifier was claimed) — the
        // engine renders wrong/expired codes inline and keeps the user on the
        // screen; only unrecoverable failures reach here.
        _showError(failure.localizedMessage());
      case OtpCancelled<ClientVerifyResult>():
      case OtpExpired<ClientVerifyResult>():
        // Handled inline by the OTP engine; nothing to route.
        break;
    }
  }

  /// Server decides new-vs-returning: on an ACTIVE session, `user.name == null`
  /// means profile setup is incomplete (→ Enter Name); otherwise the client is
  /// fully set up (→ authenticated app). Non-ACTIVE statuses route to their
  /// dedicated screens.
  Future<void> _handleVerified(ClientVerifyResult data) async {
    switch (data.status) {
      case AuthAccountStatus.active:
        final accessToken = data.accessToken;
        final refreshToken = data.refreshToken;
        if (accessToken == null || refreshToken == null) {
          _showMalformed();
          return;
        }
        // Reuse the shared ACTIVE-login write path: prime tokens → GET /me →
        // persist the full session (flips auth status → authenticated so the
        // router guard opens protected routes). No second session manager.
        final userResult = await completeActiveLogin(
          accessToken: accessToken,
          refreshToken: refreshToken,
          getCurrentUser: sl<GetCurrentUserUseCase>(),
          sessionManager: sl<SessionManager>(),
        ).run();
        if (!mounted) return;
        userResult.match(
          (failure) => _showError(failure.localizedMessage()),
          (_) {
            if (data.user?.name == null) {
              context.push(AccountSetupRoutes.enterName);
            } else {
              context.go(ClientRoutes.home);
            }
          },
        );
      case AuthAccountStatus.suspended:
        context.go(AuthRoutes.suspended);
      case AuthAccountStatus.scheduledForDeletion:
        context.go(AuthRoutes.scheduledForDeletion);
      case AuthAccountStatus.incomplete:
        // Not part of the client verify contract (ACTIVE | SUSPENDED |
        // SCHEDULED_FOR_DELETION) — treat defensively as malformed.
        _showMalformed();
    }
  }

  void _showMalformed() => _showError('auth.malformed_login_response'.tr());

  void _showError(String title) {
    if (!mounted) return;
    showAppErrorSnackbar(context: context, title: title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavBar(
        title: '',
        showBackButton: true,
        onLeadingTap: () => context.pop(),
      ),
      body: SafeArea(
        child: OtpHost<ClientVerifyResult>(
          config: widget.config,
          onResult: _handleResult,
        ),
      ),
    );
  }
}
