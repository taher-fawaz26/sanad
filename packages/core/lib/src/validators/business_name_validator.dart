import 'package:core/src/validators/meaningful_text_validator.dart';

/// Business/organization/service/role name validation — pure Dart.
///
/// Names must carry meaningful content (see [MeaningfulTextValidator]) and
/// are limited to letters, digits, spaces, and the punctuation that
/// naturally appears in business names: hyphen, apostrophe, ampersand,
/// period, and comma (e.g. "A & B Services", "24-Hour Plumbing Co.").
abstract final class BusinessNameValidator {
  BusinessNameValidator._();

  static final RegExp _allowedCharacters = RegExp(
    r"^[\p{L}\p{Nd}\s\-'&.,]+$",
    unicode: true,
  );

  static bool isValid(String? value) {
    if (!MeaningfulTextValidator.isValid(value)) return false;
    return _allowedCharacters.hasMatch(value!.trim());
  }
}
