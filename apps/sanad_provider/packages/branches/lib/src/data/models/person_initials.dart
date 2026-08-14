import 'package:core/core.dart';

/// Returns up to two uppercase initials from a person's full name.
///
/// Examples: `"Ali Hassan"` → `"AH"`, `"Taher"` → `"T"`, `""` → `""`.
String personInitials(String name) => initialsOf(name) ?? '';
