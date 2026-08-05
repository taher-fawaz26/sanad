import 'package:organization_settings/src/domain/entities/organization_contact_entity.dart';

/// Tolerant DTO for `GET organizations/me/contact` — unwraps a `data`
/// envelope and matches common field aliases.
class OrganizationContactResponse {
  const OrganizationContactResponse({
    this.phone,
    this.email,
    this.phoneVerified = false,
    this.emailVerified = false,
  });

  factory OrganizationContactResponse.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);
    return OrganizationContactResponse(
      phone: _firstString(map, const ['phone', 'phoneNumber']),
      email: _firstString(map, const ['email', 'businessEmail']),
      phoneVerified: _firstBool(
        map,
        const ['phoneVerified', 'isPhoneVerified'],
      ),
      emailVerified: _firstBool(
        map,
        const ['emailVerified', 'isEmailVerified'],
      ),
    );
  }

  final String? phone;
  final String? email;
  final bool phoneVerified;
  final bool emailVerified;

  OrganizationContactEntity toEntity() => OrganizationContactEntity(
    phone: phone,
    email: email,
    phoneVerified: phoneVerified,
    emailVerified: emailVerified,
  );

  static Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    return raw;
  }

  static String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  static bool _firstBool(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) return value;
    }
    return false;
  }
}
