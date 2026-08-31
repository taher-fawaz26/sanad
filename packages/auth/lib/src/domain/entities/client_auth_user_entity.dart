import 'package:equatable/equatable.dart';

/// The `user` object returned by `POST auth/client/verify`.
///
/// Present only when a session was issued (`status == ACTIVE`). [name] is
/// `null` until the client sets it via `PATCH clients/me` — a `null` [name] on
/// an ACTIVE verify is the server's "first-time client, profile setup
/// incomplete" cue. [email] is `null` for phone-registered clients and [phone]
/// is `null` for email-registered clients.
class ClientAuthUser extends Equatable {
  const ClientAuthUser({
    required this.id,
    required this.preferredLanguage,
    this.name,
    this.email,
    this.phone,
  });

  final String id;
  final String? name;
  final String? email;
  final String? phone;

  /// `"en"` or `"ar"`; the backend defaults it to `"en"`, never `null`.
  final String preferredLanguage;

  @override
  List<Object?> get props => [id, name, email, phone, preferredLanguage];
}
