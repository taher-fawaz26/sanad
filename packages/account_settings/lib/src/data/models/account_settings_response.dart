import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/enums/preferred_language.dart';

/// DTO for `PATCH account-settings` and `PATCH clients/me`.
///
/// Backend spec: `name`, `phone`, and `email` are nullable (`email` is `null`
/// for phone-registered clients); `id` and `preferredLanguage` are required.
class AccountSettingsResponse {
  const AccountSettingsResponse({
    required this.id,
    required this.preferredLanguage,
    this.email,
    this.name,
    this.phone,
  });

  factory AccountSettingsResponse.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);
    return AccountSettingsResponse(
      id: map['id'] as String,
      name: map['name'] as String?,
      email: _nullableString(map['email']),
      phone: _nullableString(map['phone']),
      preferredLanguage: PreferredLanguage.fromApi(
        map['preferredLanguage'] as String? ?? 'en',
      ),
    );
  }

  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final PreferredLanguage preferredLanguage;

  AccountSettingsEntity toEntity() => AccountSettingsEntity(
    id: id,
    name: name,
    email: email,
    phone: phone,
    preferredLanguage: preferredLanguage,
  );

  static Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    return raw;
  }

  static String? _nullableString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
