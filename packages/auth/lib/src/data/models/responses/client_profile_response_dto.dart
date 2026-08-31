import 'package:auth/src/domain/entities/client_profile_entity.dart';

/// Data model for [ClientProfile] — the full profile returned by
/// `PATCH clients/me`. `email`/`phone` are nullable (email-only vs phone-only
/// clients); `preferredLanguage` defaults to `"en"`.
class ClientProfileResponseModel extends ClientProfile {
  const ClientProfileResponseModel({
    required super.id,
    required super.preferredLanguage,
    super.name,
    super.email,
    super.phone,
  });

  factory ClientProfileResponseModel.fromJson(Map<String, dynamic> json) {
    // Some endpoints wrap the payload in a `data` envelope; tolerate both.
    final data = json['data'];
    final map = data is Map<String, dynamic> ? data : json;
    return ClientProfileResponseModel(
      id: map['id'] as String,
      name: map['name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      preferredLanguage: map['preferredLanguage'] as String? ?? 'en',
    );
  }
}
