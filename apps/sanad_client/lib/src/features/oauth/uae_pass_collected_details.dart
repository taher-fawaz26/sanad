import 'package:equatable/equatable.dart';

/// The three fields UAE PASS hands back after approval, as shown on the
/// "We collect data from UAE PASS" and "You're all set!" screens.
///
/// UI-only for this phase — there is no real UAE PASS SDK integration yet
/// (see `OAuthUaePassPage`'s class doc), so nothing populates this from a
/// live response. `placeholder` holds the exact preview values from Figma
/// (`7020:28255` / `7043:28742`) so the two screens render correctly today;
/// once the real integration exists, its result should be threaded through
/// as a route `extra` instead of the placeholder, with no other UI changes.
class UaePassCollectedDetails extends Equatable {
  /// Creates a [UaePassCollectedDetails].
  const UaePassCollectedDetails({
    required this.fullName,
    required this.verifiedIdentityLabel,
    required this.maskedMobileNumber,
  });

  /// Figma preview values (`7020:28255` / `7043:28742`) — not real user data.
  factory UaePassCollectedDetails.placeholder() {
    return const UaePassCollectedDetails(
      fullName: 'Mohamed Shahat',
      verifiedIdentityLabel: 'Emirates ID • Verified by UAE PASS',
      // Server-masked display value (mirrors `OtpDelivery.maskedDestination`'s
      // masking-is-server-side convention) — not computed client-side.
      maskedMobileNumber: '+971 5 • • • • • • 28',
    );
  }

  /// e.g. "Mohamed Shahat".
  final String fullName;

  /// e.g. "Emirates ID • Verified by UAE PASS".
  final String verifiedIdentityLabel;

  /// Server-masked display value, e.g. "+971 5 • • • • • • 28".
  final String maskedMobileNumber;

  @override
  List<Object?> get props => [
    fullName,
    verifiedIdentityLabel,
    maskedMobileNumber,
  ];
}
