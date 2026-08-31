import 'package:equatable/equatable.dart';

/// Body for `PATCH clients/me` — sets the client display [name] and/or
/// [preferredLanguage]. Only non-null fields are serialized; an empty body is
/// rejected by the backend (400), so callers must send at least one field.
class UpdateClientProfileRequest extends Equatable {
  const UpdateClientProfileRequest({this.name, this.preferredLanguage});

  final String? name;

  /// `"en"` or `"ar"`.
  final String? preferredLanguage;

  Map<String, dynamic> toMap() => {
    if (name != null) 'name': name,
    if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
  };

  @override
  List<Object?> get props => [name, preferredLanguage];
}
