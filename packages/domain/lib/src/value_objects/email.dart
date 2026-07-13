import 'package:equatable/equatable.dart';

final _emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+\.\w{2,}$');

/// Validated email address value object.
class Email extends Equatable {
  const Email._(this.value);

  /// Parses and validates [raw], returning a lowercased [Email].
  factory Email.fromString(String raw) {
    final trimmed = raw.trim();
    if (!_emailRegex.hasMatch(trimmed)) {
      throw ArgumentError('Invalid email address: $raw');
    }
    return Email._(trimmed.toLowerCase());
  }

  /// The canonical (trimmed, lowercase) email string.
  final String value;

  @override
  String toString() => value;

  @override
  List<Object?> get props => [value];
}
