import 'package:equatable/equatable.dart';

/// Full client profile returned by `PATCH clients/me` — used to refresh local
/// state after the display name / preferred language is saved.
///
/// [email] is `null` for phone-registered clients and [phone] is `null` for
/// email-registered clients.
class ClientProfile extends Equatable {
  const ClientProfile({
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
  final String preferredLanguage;

  @override
  List<Object?> get props => [id, name, email, phone, preferredLanguage];
}
