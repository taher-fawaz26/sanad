import 'package:auth/src/domain/entities/auth_account_settings_entity.dart';

/// Data model for [AuthAccountSettingsEntity] — the `accountSettings` object
/// embedded in `AuthSessionResponseDto`.
class AuthAccountSettingsModel extends AuthAccountSettingsEntity {
  const AuthAccountSettingsModel({
    required super.id,
    required super.email,
    required super.preferredLanguage,
    super.name,
    super.phone,
  });

  factory AuthAccountSettingsModel.fromJson(Map<String, dynamic> json) {
    final preferredLanguage = json['preferredLanguage'];
    if (preferredLanguage is! String ||
        !_allowedLanguages.contains(preferredLanguage)) {
      throw FormatException(
        'AuthAccountSettingsModel.preferredLanguage: expected "ar" or "en", '
        'got $preferredLanguage.',
      );
    }
    return AuthAccountSettingsModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      preferredLanguage: preferredLanguage,
    );
  }

  static const _allowedLanguages = {'ar', 'en'};

  /// Returns a copy with the given fields replaced.
  ///
  /// [name] and [phone] use a sentinel default so omitting an argument keeps
  /// the current value and explicitly passing `null` clears it — the same
  /// idiom used by `AuthSessionEntity.copyWith`.
  AuthAccountSettingsModel copyWith({
    String? id,
    String? email,
    String? preferredLanguage,
    Object? name = _copyWithSentinel,
    Object? phone = _copyWithSentinel,
  }) {
    return AuthAccountSettingsModel(
      id: id ?? this.id,
      email: email ?? this.email,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      phone: identical(phone, _copyWithSentinel)
          ? this.phone
          : phone as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'preferredLanguage': preferredLanguage,
  };
}

/// Private sentinel — see [AuthAccountSettingsModel.copyWith].
const Object _copyWithSentinel = Object();
