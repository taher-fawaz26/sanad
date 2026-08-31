import 'package:equatable/equatable.dart';
import 'package:otp/otp.dart';

/// `extra` payload for `OAuthRoutes.otp` (see `client_router.dart`'s
/// registration of that path).
///
/// Mirrors `packages/auth`'s `AuthOtpRouteArgs` — the same typed-`extra`
/// pattern `.claude/rules/routing.md` documents for passing non-serializable
/// context through `go_router`.
class OAuthOtpRouteArgs extends Equatable {
  /// Creates an [OAuthOtpRouteArgs].
  const OAuthOtpRouteArgs({required this.channel, required this.destination});

  /// Whether the OTP screen was reached from `OAuthEmailPage` or
  /// `OAuthPhonePage`.
  final OtpChannel channel;

  /// The email or phone value the user actually entered — never a hardcoded
  /// placeholder. Phone destinations arrive already normalized (see
  /// `OAuthPhonePage`'s use of `UaePhoneValidator.normalize`, the same
  /// convention `contact_change_sheet.dart` uses).
  final String destination;

  @override
  List<Object?> get props => [channel, destination];
}
