import 'package:equatable/equatable.dart';

/// Account settings snapshot embedded in an authenticated session response.
///
/// Provider-owner accounts only — `null` on the parent `AuthSessionEntity`
/// for clients and workers (see `AuthSessionResponseDto.accountSettings`).
///
/// Deliberately NOT the `AccountSettingsEntity` from the `account_settings`
/// package: that package depends on `auth`, so importing it back here would
/// be circular. This is a minimal, auth-local read of the same wire shape,
/// used only to avoid dropping the field during session parsing — the
/// account_settings feature still owns the authoritative `GET
/// /account-settings` read/write flow.
class AuthAccountSettingsEntity extends Equatable {
  const AuthAccountSettingsEntity({
    required this.id,
    required this.email,
    required this.preferredLanguage,
    this.name,
    this.phone,
  });

  final String id;

  /// Nullable per `AuthSessionResponseDto.accountSettings.name`.
  final String? name;

  /// Nullable for phone-registered clients — `client/profile`'s
  /// `accountSettings.email` is no longer guaranteed (see client-auth update).
  final String? email;

  /// Null until verified via the contact-verification flow.
  final String? phone;

  /// `"ar"` or `"en"`.
  final String preferredLanguage;

  @override
  List<Object?> get props => [id, name, email, phone, preferredLanguage];
}
