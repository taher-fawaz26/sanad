import 'package:account_settings/src/domain/enums/preferred_language.dart';
import 'package:equatable/equatable.dart';

/// Account settings profile for the signed-in provider user.
class AccountSettingsEntity extends Equatable {
  const AccountSettingsEntity({
    required this.id,
    required this.email,
    required this.preferredLanguage,
    this.name,
    this.phone,
  });

  final String id;

  /// Nullable per `AccountSettingsDto.name` (backend field is `nullable: true`).
  final String? name;

  final String email;
  final String? phone;
  final PreferredLanguage preferredLanguage;

  bool get hasPhone => phone != null && phone!.isNotEmpty;

  @override
  List<Object?> get props => [id, name, email, phone, preferredLanguage];
}
