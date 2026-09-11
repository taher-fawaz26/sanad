import 'package:app_animations/app_animations.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The conversation-level state of the wire — Figma `message-pending-offline`
/// and `message-send-failed`.
///
/// Two conditions, deliberately distinguished and deliberately ranked.
///
/// **Distinguished**, because they are not the same thing and the user would
/// act differently on each: offline means nothing can be sent yet and the
/// queued turns go out on their own; a send failure means one turn was
/// attempted and did not arrive, and only Retry moves it.
///
/// **Ranked**, with offline winning: while the radio is off, telling the user
/// to "check your network connection" under a banner that already says there
/// is no network would say the same thing twice and ask them to fix something
/// they can already see. The failed bubbles keep their own footers either way,
/// so nothing is hidden — only the banner defers.
///
/// `AppAlert` rather than a hand-rolled strip, so the warning and error
/// surfaces come from the design system instead of a pair of literals.
class AiTransportBanner extends StatelessWidget {
  /// Creates the banner. Renders nothing when neither condition holds.
  const AiTransportBanner({
    required this.isOffline,
    required this.hasUndeliveredMessage,
    super.key,
  });

  /// The device cannot reach the network.
  final bool isOffline;

  /// At least one user turn was attempted and did not arrive.
  final bool hasUndeliveredMessage;

  _BannerVisibility get _visibility {
    if (isOffline) return _BannerVisibility.offline;
    if (hasUndeliveredMessage) return _BannerVisibility.failed;
    return _BannerVisibility.hidden;
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedSize so the composer above doesn't jump as the banner's height
    // appears/disappears; AppStateTransition cross-fades the banner's own
    // content (or absence of it) between the three states. Functional motion
    // — a real change in whether the wire is up — so not gated by reduced
    // motion, matching AppStateTransition's own policy.
    return AnimatedSize(
      duration: AppMotionDuration.normal,
      curve: AppMotionCurve.standard,
      alignment: AlignmentDirectional.topCenter,
      child: AppStateTransition<_BannerVisibility>(
        value: _visibility,
        builder: (context, value) {
          if (value == _BannerVisibility.hidden) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: AppAlert(
              message: value == _BannerVisibility.offline
                  ? 'ai_chat.offline_banner'.tr()
                  : 'ai_chat.send_failed_banner'.tr(),
              type: value == _BannerVisibility.offline
                  ? AppAlertType.warning
                  : AppAlertType.error,
            ),
          );
        },
      ),
    );
  }
}

enum _BannerVisibility { hidden, offline, failed }
