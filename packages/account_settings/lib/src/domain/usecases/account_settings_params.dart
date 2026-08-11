import 'package:account_settings/src/domain/enums/preferred_language.dart';
import 'package:equatable/equatable.dart';

/// Partial update payload for `PATCH account-settings`.
class UpdateAccountSettingsParams extends Equatable {
  const UpdateAccountSettingsParams({
    this.name,
    this.preferredLanguage,
  }) : assert(
         name != null || preferredLanguage != null,
         'At least one field must be provided',
       );

  final String? name;
  final PreferredLanguage? preferredLanguage;

  @override
  List<Object?> get props => [name, preferredLanguage];
}
