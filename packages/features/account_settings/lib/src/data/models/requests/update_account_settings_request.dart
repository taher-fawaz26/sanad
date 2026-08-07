import 'package:account_settings/src/domain/enums/preferred_language.dart';
import 'package:equatable/equatable.dart';

/// PATCH body for `account-settings` — only non-null fields are serialized.
class UpdateAccountSettingsRequest extends Equatable {
  const UpdateAccountSettingsRequest({
    this.name,
    this.preferredLanguage,
  }) : assert(
         name != null || preferredLanguage != null,
         'At least one field must be provided',
       );

  final String? name;
  final PreferredLanguage? preferredLanguage;

  Map<String, dynamic> toMap() {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (preferredLanguage != null) {
      body['preferredLanguage'] = preferredLanguage!.toApi();
    }
    return body;
  }

  @override
  List<Object?> get props => [name, preferredLanguage];
}
